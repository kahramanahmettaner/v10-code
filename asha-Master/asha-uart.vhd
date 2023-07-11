--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.std_logic_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--! @brief Ein einfacher, selbstsyncronisierender, ungepufferter UART.
--! @details 8n1 - 8 Datenbits, keine Parity, ein Stoppbit
--! Erkennt die UART-Geschwindigkeit in einer Initialisierungsphase
--! in der allerdings erst einmal alle Daten verworfen werden.
entity AshaUART is
    Port ( Clock : in std_logic; --! Taktsignal
           Reset : in std_logic; --! Resetsignal
           --InSync : out std_logic; --! High wenn Baudrate erkannt wurde
           DataIn : in std_logic_vector (7 downto 0); --! Dateneingang des Moduls
           DataOut : out std_logic_vector (7 downto 0); --! Datenausgang des Moduls
           RXD : in std_logic;     --! Serieller Eingang
           TXD : out std_logic;    --! Serieller Ausgang
           DoWrite : in std_logic;      --! Signalisiert, dass DataIn gesendet werden soll
           Ready2Send : out std_logic; --! Signalisiert, dass die UART sendebereit ist
           -- TXFIN : out std_logic;  -- DataIn is sent
           --DBGLED : out std_logic_vector(7 downto 0);
           --SignalWidth : out std_logic_vector(15 downto 0); --! Uart-Signalbreite in Anzahl der Systemtakte
           RxFin : out std_logic); --! Signalisiert, dass DataOut neue Daten enthaelt
end AshaUART;

--! @brief Einfacher, selbstsyncronisierender, ungepufferter UART.
--! @details Erkennt die UART-Geschwindigkeit in einer Initialisierungsphase,
--! in der allerdings erst einmal alle Daten verworfen werden.
--! 8n1 - 8 Datenbits, keine Parity, ein Stoppbit
--! Nach der Initialisierungsphase wird die Geschwindigkeit 
--! (besser: die Signalbreite anhand der Anzahl der zu wartenden Systemtakte) 
--! in einem Register gespeichert.
--! Full-Duplex-faehig: unabhaengige Sende- und Empfangsprozesse
architecture Behavioral of AshaUART is

constant SignalWidth_CTR : unsigned(15 downto 0) := x"1458"; --! Signalbreite, wie viele Takte ist das UART-Signal breit
signal RXD_CTR : unsigned(15 downto 0); --! counter: Zaehler fuer den Empfaenger (zaehlt die Signalbreite ab)
signal TXD_CTR : unsigned(15 downto 0); --! counter: Zaehler fuer den Sender (zaehlt die Signalbreite ab)
signal TXD_STATE : unsigned(3 downto 0); --! Zustand des Senders: Welches Bit des Bytes wird gerade versendet
signal WIDTH_REG : unsigned(15 downto 0); --! Hilfsregister zur Baudratenerkennung

-- Zaehler im UART-Geschwindigkeits-Detektor
constant MAX_EQCTR   : integer := 15;
constant MAX_UNEQCTR : integer := 15;
signal EQUAL_CTR   : integer range 0 to MAX_EQCTR; --! Zaehlt die gleichen Signalbreiten
signal UNEQUAL_CTR : integer range 0 to MAX_UNEQCTR; --! Zaehlt die ungleichen Signalbreiten
constant MIN_SIGNAL_WIDTH : integer := 63;

signal BYTE : unsigned(8 downto 0); --! Empfangsschieberegister, puffert das empfangene Byte
signal SEND_BUF : std_logic_vector(12 downto 0); --! Sendepuffer  (TODO: Default Value Warnings)
signal RATE_DETECTED : std_logic; -- 0=false, 1=true --! True, wenn Baudrate ermittelt wurde, gleichzeitig indikator fuer normalen Sendebetrieb
signal DETECTION_IN_PROGRESS : std_logic; -- 0=false, 1=true --! Eine Taktflanke wurde erkannt, Breitenerkennung im Gange
signal RECEIVING_IN_PROGRESS : std_logic; -- 0=false, 1=true --! Der Empfaenger hat das Startbit erkannt und bearbeteitet nun die weiteren Bits
signal START_RECEIVED : std_logic; -- 0=false, 1=true --! UART START-Bit empfangen
-- signal LAST_SIGNAL : std_logic := '0';
signal SENDING : std_logic;

--signal DEBUG : std_logic := '0';

begin
  -- TXFIN<=DETECTION_IN_PROGRESS; --debug
  Process (SENDING, RATE_DETECTED, DoWrite)
  begin
    Ready2Send<=(not SENDING) and RATE_DETECTED and (not DoWrite); -- DoWrite muss rein, damit Ready2Send sofort 0 wird
  end Process;

  --! Detektiert die UART-Geschwindigkeit
  --! Misst nur die Breite der Low-Pegel,
  --! da es bei der Beruecksichtigung von Low und High Pegeln das 
  --! Problem gibt, dass die Flankensteilheit der Pegelwechsel 
  --! unterschiedlich sind und daher 0- und 1-bit generell unterschiedlich
  --! breit sein koennen. (Ist bei unserem Modul nicht der Fall, aber 
  --! je nach Routing passiert das im FPGA!)
  --! Hierzu wird immer der kleinst-breiteste Low-Pegel bestimmt und derer
  --! muessen 15 (MAX_EQCTR) erkannt werden, bevor 15 (MAX_UNEQCTR) andere
  --! auftreten, sonst wird die Messung zurueckgesetzt.
  --! Wird waehrend der Messung ein weniger breiter Low-Pegel erkannt, wird
  --! dieser als Vergleichswert gesetzt und die Zaehler zurueckgesetzt.
  Process (Clock)
  begin
   if rising_edge(Clock) then
    if (Reset='1') then
--      RATE_DETECTED<='0';						-- variable
--      SignalWidth_CTR<=(others=>'0');		--	
		Rate_DETECTED<='1';							-- fix
      WIDTH_REG<=(others=>'1');
      EQUAL_CTR<=0;
      UNEQUAL_CTR<=0;
      DETECTION_IN_PROGRESS<='0';
      
      else
       if (DETECTION_IN_PROGRESS='1') then -- 0->1 Flanke
        -- Hier endet die Messung der Signalbreite.
        -- Wir haben die letzte Signalbreite mit SignalWidth_CTR
        -- gemessen.

        DETECTION_IN_PROGRESS<='0'; -- Ende der Messung

        -- Wenn die gemessene Breite ungefaehr der bisher kleinsten entspricht
        if WIDTH_REG(15 downto 1)=SignalWidth_CTR(15 downto 1) then
          UNEQUAL_CTR<=0; -- dann wird der Zaehler falscher zurueckgesetzt
          if EQUAL_CTR=MAX_EQCTR then -- wenn genuegend kleinste gezaehlt
            -- dann haben wir die uart-rate erkannt
            RATE_DETECTED<='1';
          else
            -- andernfalls haben wir immerhin einen mehr
            EQUAL_CTR<=EQUAL_CTR+1;
          end if;
        else -- wenn breite diesmal anders
          UNEQUAL_CTR<=UNEQUAL_CTR+1; -- dann haben wir einen Ungleichen mehr
          if UNEQUAL_CTR=MAX_UNEQCTR then
            -- wenn zu viele Falsche, dann haben wir vielleicht mal einen 
            -- einzelnen viel zu kleinen gemessen und fangen die Messung
            -- lieber wieder mit dem Aktuellen als Startwert von vorne an
            WIDTH_REG<=SignalWidth_CTR; 
            EQUAL_CTR<=0;
            UNEQUAL_CTR<=0; -- TODO: ist das noetig??
          elsif (SignalWidth_CTR>MIN_SIGNAL_WIDTH)
                and (SignalWidth_CTR<WIDTH_REG) then
            -- wenn wir einen kleineren haben, dann moechten wir diesen
            -- als aktuellen Vergleichswert speichern, da wir ja den 
            -- kleinsten haben wollen.
            WIDTH_REG<=SignalWidth_CTR;
            EQUAL_CTR<=0;
            UNEQUAL_CTR<=0;
          end if;
        end if;
       end if; 
       -- innerhalb eines 1-Bits machen wir nichts
     end if;
    end if;
  end Process;

--! Eigenstaendiger Prozess für den Uart-Sender
  -- sobald das Hauptmodul mit DoWrite='1'
  Process (Clock) -- Sender
  begin
    if rising_edge(Clock) then
      if (Reset='1') or (RATE_DETECTED='0') then -- Reset
        SENDING<='0';
        TXD<='1'; -- wenn nichts passiert, liegt an Uart-Leitungen High-Pegel
      else
        if (SENDING='1') then
          if (TXD_CTR=(TXD_CTR'range=>'0')) then -- TXD_CTR=0 , 'range ist die breite und alle 0
            TXD_CTR<=TXD_CTR+1;
            TXD<=SEND_BUF(to_integer(TXD_STATE));
            if (TXD_STATE=10) then
              SENDING<='0';
              TXD<='1';
            end if;
            TXD_STATE<=TXD_STATE+1;
          -- Wenn der TXD_CTR so viel gezaehlt hat, wie die Signalbreite ist, 
          -- dann wird er auf 0 gesetzt, was obiges ausloest^^
          elsif (TXD_CTR=SignalWidth_CTR) then 
            TXD_CTR<=(others=>'0');
          else 
            TXD_CTR<=TXD_CTR+1;
          end if; -- sending=1
        elsif (DoWrite='1') then -- TODO: vielleicht besser in eigenem "if"?
          -- Wir sollen schreiben (Signal vom Hauptmodul), 
          -- hier also die Initialisierung fuer diesen Vorgang
          SENDING<='1';
          -- SEND_BUF<='1111' & DataIn & '0';-- das geht leider so nicht, also:
          SEND_BUF(12)<='1';
          SEND_BUF(11)<='1';
          SEND_BUF(10)<='1';
          SEND_BUF(9)<='1';
          SEND_BUF(0)<='0';
          SEND_BUF(8 downto 1)<= DataIn; -- warum geht das aber oben das nicht?
          TXD_STATE<="0000";
          TXD_CTR<=(others=>'0');
        end if;
      end if;
    end if;
  end Process;

  --! Eigenstaendiger Prozess für den Empfaenger
  Process (Clock) -- Empfaenger
  begin
    if rising_edge(Clock) then
      if (Reset='1') or (RATE_DETECTED='0') then
        RECEIVING_IN_PROGRESS<='0';
        RxFin<='0';
        START_RECEIVED<='0';
        RXD_CTR<=(others=>'0');
        BYTE<=(others=>'0');
      else
        RXD_CTR<=RXD_CTR+1;  -- mit jedem Takt den Counter erhoehen
        RxFin<='0';          -- mit jedem Takt RxFin auf 0 setzen
        if (RECEIVING_IN_PROGRESS='1') then -- Das Startbit wurde erkannt
          if (START_RECEIVED='1') then -- Wir sind nicht mehr im Startbit
            if (RXD_CTR = SignalWidth_CTR) then
              RXD_CTR<=(others=>'0');
              BYTE<=RXD & BYTE(8 downto 1); -- Empfang in ein Schieberegister
                -- RXD wird hoestwertigstes, alle anderen nach rechts verschoben.
            end if;
            if (BYTE(0)='1') then
              RECEIVING_IN_PROGRESS<='0'; -- ... sind wir fertig mit dem Empfang
              -- START_RECEIVED<='0'; -- unnoetig
              DataOut<=std_logic_vector(BYTE(8 downto 1));
              -- TODO: RxFin einen Takt verzoegern!
              -- RxFin<='1'; -- Dem Aufrufer Bescheid geben: wir sind fertig
            end if;            
          elsif (RXD_CTR = '0' & SignalWidth_CTR(15 downto 1)) then -- halbe Signalbreite (somit Signalmitte)
            RXD_CTR<=(others=>'0');
            START_RECEIVED<='1';
            BYTE<="100000000"; -- Die "Starteins" (s.o.)
          end if;
        elsif (RXD='0') and (START_RECEIVED='0') then -- Wir empfangen noch nichts, empfangen aber eine logische 0, d.h.: jetzt kommt ein UART-Paket
          RXD_CTR<=(others=>'0'); -- Zaehler zuruecksetzen
          RECEIVING_IN_PROGRESS<='1'; -- Wir empfangen ein Paket
          -- (ist schon) START_RECEIVED<='0'; -- Wir müssen das Startbit abwarten 
        elsif START_RECEIVED='1' and (RXD_CTR = SignalWidth_CTR) then -- Das Stopbit muss noch abgearbeitet werden
          RXD_CTR<=(others=>'0');
          START_RECEIVED<='0'; -- naechstes Startbit kann erkannt werden
          if RXD='1' then -- Stopbit erkannt
            RxFin<='1'; -- Daten fertig gelesen (und DataOut muesste jetzt bereit sein)
          end if;
        end if;
        
      end if;
    end if;
  end Process;  

end Behavioral;

