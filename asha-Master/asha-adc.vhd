--! Standardbibliothek benutzen
library IEEE;

--! Logikelemente verwenden
use IEEE.std_logic_1164.ALL;

--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! eigene Typdefinitionen
library work;
use work.AshaTypes.ALL;

--! @brief  steuert den externen ADC und linearisiert dessen Werte.
--! @details Der Spartan 3 hat keine analogen Eingaenge, daher muessen
--! entsprechende analoge Messwerte anderweitig eingelesen werden.
--! Dies geschieht hier durch einen MCP3208, einen 8-Kanal 
--! Analog-Digital-Converter mit serieller SPI-Schnittstelle. 
--! Dieses Modul implementiert das SPI-Protokoll fuer diesen ADC,
--! liesst dessen Eingaenge aus, linearisiert diese, so dass
--! anhand der Grenzwerte in die passende physikalische Einheit
--! umgerechnet werden kann und speichert die Daten in einem 
--! Array (ADCRegister) 
entity AshaADC is
  Port ( 
    Clock : in std_logic; --! Taktsignal
    Reset : in std_logic; --! Resetsignal
    ADCClockIn : in std_logic; --! Taktsignal fuer den ADC
    ADCReceive :  in std_logic; --! Datenleitung vom externen ADC
    ADCSend : out std_logic; --! Datenleitung zum externen ADC
    ADCChipSelect : out std_logic; --! Chipselect-Leitung zum externen ADC
    ADCRegister : out ADCRegisterType; --! Datenregister aller ADC-Werte
    ADCClockOut : out std_logic); --! Taktsignal fuer den ADC
end AshaADC;

architecture Behavioral of AshaADC is
    
  signal ADCClockOld, EnADCClock : std_logic;

  -- ADC-Wertholprozess meldet der ADC LOOP: Wert fertig gelesen wurde
  signal ADCValueReady : std_logic;

  type ADCTransStateType is (setaddr,waitaddr,waitaddr2,mulvalue,addvalue,dataready);
  signal ADCTransState: ADCTransStateType;

  -- Datentransfer ADC Linearisierung -> ADC Loop
  signal ADCLinearData : std_logic_vector(11 downto 0); 

  -- Zwischenspeicher eines Multiplikationsergebnisses
  signal ADCLinearMultiply : std_logic_vector(13 downto 0);

  -- Signale fuer das ADCTranslation Block Ram Core Module
  signal ATMemAddr : std_logic_vector(8 downto 0); -- 8-6: ADC Addresse, 5-0: Nachschlagewert (Die ersten 6 Bits des gemessenen Wertes werden im Speicher zur Linearisierung nachgeschlagen)
  signal ATMemData : std_logic_vector(19 downto 0); -- 19-8: Der linearisierte Wert, 7-0: Der Multiplikator fur Zwischenwerte 2**6

  signal ADCLoopState: ADCLoopStateType; -- Statemachine Main ADC LOOP
  signal ADCNumber : unsigned(2 downto 0); -- Aktuelle ADC-Nummer im ADC LOOP

  -- Signalisierung von LOOP an ADC-Wertholprozess: Hole Wert.
  signal ADCGetValue : std_logic; 

  -- Signalisierung von LOOP an Linearisierung: Uebersetze
  -- Signalisierung von Linearisierung an KOOP: fertig
  signal TranslateValue, ADCTranslationReady : std_logic;

  -- Unuebersetzte Daten von des ADC-Wertholprozesses an die LOOP
  signal ADCData : STD_LOGIC_VECTOR(11 downto 0);

  -- Zustandsmaschine des ADC-Wertholprozesses
  signal ADCState: ADCStateType;			


  -- Code Module: ROM (Speicher) zur Uebersetzung
  -- Tabellen zur Linearisierung
  component adc_translation
    port (
      clka:   IN std_logic;
      addra:  IN std_logic_vector(8 downto 0);
      douta: OUT std_logic_vector(19 downto 0));
  end component;
  
begin

  CoreModuleADCTranslation  : adc_translation
  port map (
    clka=>Clock,
    addra=>ATMemAddr,
    douta=>ATMemData
  );

  -- Der im Hauptmodul erzeugte Takt fuer den ADC wird 
  -- nur an diesen weitergereicht, wenn wir ihn benoetigen.
  ADCClockOut<=ADCClockIn and EnADCClock;

  --! @brief Main ADC Loop, koordiniert das Auslesen analoger Werte
  --! @details Folgender ADC-Aktualisierungs-Prozess ist fuer die 
  --! interne Verarbeitung der Sensoren zustaendig. 
  --! Es werden permanent alle analogen Sensoren abgefragt 
  --! und deren Werte abgespeichert.
  --! Hierzu werden in einer endlosen Schleife nacheinander
  --! die folgenden VHDL-Prozesse fuer jeden einzelnen 
  --! Sensor abgearbeitet:
  --!  -  ADC Wertholprozess (Wert vom physischen ADC holen)
  --!  -  ADC Linearisierung
  --! Die fertigen Daten werden im ADCRegister abgespeichert.
  Process (Clock) -- ADC LOOP
  begin
    if rising_edge(Clock) then
      -- DEVICES_LOOP
        -- DEVICE_STATE
      if Reset='1' then -- Reset
        ADCLoopState<=s_getvalue; -- Startzustand
        ADCNumber<=(others=>'0'); 
        ADCGetValue<='0'; -- Subprozesse deaktivieren
        TranslateValue<='0'; -- s.o.
        -- ADC_WatchDog<=(others=>'0');
        --ReglerTempIst<=0;
        --ReglerLichtIst<=0;
      else
        case ADCLoopState is
        when s_getvalue =>
          ADCGetValue<='1'; -- dem ADC Wertholprozess Bescheid geben
          -- ADC_WatchDog<=ADC_WatchDog+1;-- TODO: watchdog, wir koennten das ready des externen adc ueberhoeren
          if ADCValueReady='1' then -- wenn Wert da
            ADCGetValue<='0'; 
            TranslateValue<='1'; -- als naechstes linearisieren
            ADCLoopState<=s_translate;
            -- if ADCNumber=x"2" then
            --   DEBUG_DATA<="0000" & ADCData;
            -- end if;
          end if;
        when s_translate =>
          TranslateValue<='1';
          if ADCTranslationReady='1' then
            TranslateValue<='0';
            ADCRegister(to_integer(ADCNumber))<=ADCLinearData;
--            if ADCNumber=x"0" then -- Innentemperatur, für die Regelung (Direktzugriff)
--              ReglerTempIst<=to_integer(unsigned(ADCLinearData));
--              -- DEBUG_DATA<=ADCLinearData;
--            elsif ADCNumber=x"3" then -- Lichtsensor, für die Regelung (Direktzugriff)
--              ReglerLichtIst<=to_integer(unsigned(ADCLinearData));
--            --elsif ADCNumber=x"1" then
--            --  DEBUG_DATA<="0000" & ADCLinearData;
--            end if;

            ADCLoopState<=s_end;
          end if;
        when s_end =>
          ADCNumber<=ADCNumber+1;
          -- DEBUG_DATA<="000000000" & std_logic_vector(ADCNumber); -- & "11111" & not ADCNumber;
          ADCLoopState<=s_getvalue;
        end case;
      end if;
    end if;
  end Process; -- ADC LOOP

  -- Dieser Prozess uebersetzt die vom ADC gelesenen Werte
  -- so dass sie linear verlaufen. Das heisst, so dass 
  -- ein Minimal- und Maximalwert der eigentlichen Einheit
  -- reicht und man die Zwischenwerte anhand der rohen
  -- ADC-Werte berechnen kann.
  --
  -- Reale Sensoren sind nicht linear. Als Beispiel
  -- koennte ein Wert von 0 am ADC 0 Volt bedeuten, 
  -- ein Wert von 4095 dann 3,3 Volt und ein Wert von
  -- 2047 dennoch 1,1 Volt. Ein Wert von 2047 an 
  -- die Android-App uebermittelt wurde sich jedoch
  -- zum Wert 1,65 berechnen.
  --
  -- Dieses Modul wuerde nun den Wert 2047 in 1023 
  -- uebersetzen, so dass man die 1,1 Volt aus den 
  -- 1023 ueber die Grenzwerte 0=0, 3,3=4095 richtig
  -- errechnen kann.
  --
  Process (Clock) -- ADC Linearisierung: Uebersetzt die Daten nichtlinearer Sensoren in ein lineares Verhältnis
  begin
    if rising_edge(Clock) then
      if TranslateValue='0' then -- Reset
        ADCTranslationReady<='0';
        ADCTransState<=setaddr;
        ADCLinearData(11 downto 0) <= (others=>'0'); -- TODO: unnoetig
        --LD0<='0';
        --LD1<='0';
        --LD2<='0';
        --LD3<='0';
        --LD4<='0';
        --LD5<='0';
        --LD6<='0';
        --LD7<='0';
      else
        case ADCTransState is 
          when setaddr =>
            ATMemAddr <= std_logic_vector(ADCNumber) & ADCData(11 downto 6);
            -- if ADCNumber=x"0" then
            --   DEBUG_DATA<= "0000000" & std_logic_vector(ADCNumber) & ADCData(11 downto 6);
            -- end if;
            ADCTransState<=waitaddr;
          when waitaddr =>
            -- Wir muessen einen Takt abwarten, damit die Adresse an den 
            -- Speicher angelegt wird und einen weiteren, damit die angelegte
            -- Adresse auch am Ausgang die entsprechenden anlegt.
            ADCTransState<=waitaddr2; -- TODO: ein waitaddr reicht wohl
          when waitaddr2 =>
            ADCTransState<=mulvalue;
          when mulvalue =>
            -- ATMemData: erste 12 bit sind linearisierter Wert (in 64 Stufen) und folgende 8 bit sind Multiplikator fuer die 64 Zwischenwerte.
            --              Der Multiplikator ist dabei eine Fixed-Point-Zahl ([2],[6]), daher muessen nach der Multipkikation wieder 6 Stellen abgeschnitten werden.
            -- Ich spare mir hier die Division an Ort und Stelle durch Vorberechnung des Multiplikators fuer die Zwischenwerte (in ATMemData(7 downto 0))
            --TODO: Noch ausmessen, ob das ueberhaupt funzt:
            ADCLinearMultiply <= std_logic_vector(unsigned(ADCData(5 downto 0)) * unsigned(ATMemData(7 downto 0)));
            -- Die Multiplikation dauert fuer sich einen Takt und braucht
            -- daher einen eigenen Zustand in der Zustandsmaschine.
            -- Zuerst hatte ich mulvalue und addvalue in einem Zustand
            -- und die Addition und Multiplikation hintereinander. 
            -- Was in der Simulation funktioniert und hier vielleicht 
            -- bei einem geringeren Takt auch, funktioniert mit direktem
            -- Takt des 50MHz-Quarts (Clock) nicht.
            --TODO: wie kann man ADCLinearMultiply weglassen? man muesste doch auch anders die breite aendern koennen!?
            ADCTransState<=addvalue;
          when addvalue =>
            --ADCLinearData <= ADCData;
            ADCLinearData <= std_logic_vector(unsigned(ATMemData(19 downto 8)) + unsigned(ADCLinearMultiply(13 downto 6)));
            -- ADCLinearData <= ADCData;
            -- ADCLinearData <= std_logic_vector(unsigned(ADCData(5 downto 0)) * unsigned(ATMemData(7 downto 0)));
            -- ADCLinearData <= "0000" & ADCLinearMultiply(13 downto 6);
            -- ADCLinearData <= "00" & ADCLinearMultiply;
            -- ADCLinearData <= "0000" & ATMemData(7 downto 0);
            -- ADCLinearData <= "000000" & ADCData(5 downto 0);
            ADCTransState<=dataready;
            -- TODO: vielleicht per xilinx' integriertem multiplizierer?
          when dataready =>
            ADCTranslationReady<='1';
        end case;
      end if;
    end if;  
  end Process; -- ADC Linearisierung

--
  Process (Clock) -- ADC Wertholprozess: Adresse anlegen, warten, auslesen
  begin
    if rising_edge(Clock) then
      -- rising edge erkennung:
      ADCClockOld<=ADCClockIn; -- beides nur einen Takt unterschiedlich
      
      -- jeden Takt zuruecksetzen:
      
      if ADCGetValue='0' then -- Reset
        -- ADC_ADDR<="000"; wird woanders angelegt
        EnADCClock<='0'; -- wenn wir den ADC nicht brauchen, brauchen wir auch kein ADCClock
        ADCChipSelect<='1'; 
        ADCSend<='Z';
        ADCState<=clken;
        -- ADCIrqSignal<='0';
        ADCValueReady<='0';
        --LD5<='0';
        --LD6<='0';
        --LD7<='0';
      else -- kein Reset
        if ADCClockIn='1' and ADCClockOld='0' then -- also: rising_edge(ADCClock)
          case ADCState is 
            when nbit => -- warte auf das Nullbit als Antwort
              if ADCReceive='0' then -- das funzt nur, wenn an Dout des ADC ein PullUp haengt!
                ADCState<=b11;
              end if;
            when b11 =>
              ADCSend<='Z'; -- brauchen wir nicht mehr. 
              -- Hier k�nnten wir ADCSend auch auf einen festen 1- oder 0-Wert setzen, da der ADC das Signal ab jetzt eh ignoriert, 
              -- aber immerhin handelt es sich ja hier offiziell um einen SPI-Bus...
              ADCData(11)<=ADCReceive;
              ADCState<=b10;
            when b10 =>
              ADCData(10)<=ADCReceive;
              ADCState<=b9;
            when b9 =>
              ADCData(9)<=ADCReceive;
              ADCState<=b8;
            when b8 =>
              ADCData(8)<=ADCReceive;
              ADCState<=b7;
            when b7 =>
              ADCData(7)<=ADCReceive;
              ADCState<=b6;
            when b6 =>
              ADCData(6)<=ADCReceive;
              ADCState<=b5;
            when b5 =>
              ADCData(5)<=ADCReceive;
              ADCState<=b4;
            when b4 =>
              ADCData(4)<=ADCReceive;
              ADCState<=b3;
            when b3 =>
              ADCData(3)<=ADCReceive;
              ADCState<=b2;
            when b2 =>
              ADCData(2)<=ADCReceive;
              ADCState<=b1;
            when b1 =>
              ADCData(1)<=ADCReceive;
              ADCState<=b0;
            when b0 =>
              ADCData(0)<=ADCReceive;
              ADCValueReady<='1'; -- der Sensorverarbeitungsroutine Bescheid geben
              ADCChipSelect<='1';
              ADCState<=endb;
            when others => 
              null; -- Am Ende warten wir einfach ab. Der Startzustand wird beim nächsten Auftreten von "ADCGetValue" erneut gesetzt.
          end case;
        elsif ADCClockIn='0' and ADCClockOld='1' then -- also: falling_edge(ADCClock)
          case ADCState is
          -- clken,startb,single,d2,d1,d0,nbit,b11,b10,b9,b8,b7,b6,b5,b4,b3,b2,b1,b0,endb
            when clken =>
              EnADCClock<='1'; -- Takt einschalten
              ADCSend<='0'; -- aber noch kein startbit senden
              ADCState<=startb;
            when startb => -- Beginn der ADC-Behandlung
              ADCChipSelect<='0'; -- CS ist low-active
              ADCSend<='1'; -- Startbit ist high
              ADCState<=single;
            when single =>   -- dann start einen adc-takt lang setzen
              ADCSend<='1'; -- single-ended und nicht differential
              ADCState<=d2;
            when d2=>
              ADCSend<=ADCNumber(2);
              --LD5<=ADC_ADDR(2);
              ADCState<=d1;
            when d1=>
              ADCSend<=ADCNumber(1);
              --LD6<=ADC_ADDR(1);
              ADCState<=d0;
            when d0=>
              ADCSend<=ADCNumber(0);
              --LD7<=ADC_ADDR(0);
              ADCState<=nbit;
            when others => 
              null;
          end case;
        end if; -- rising_edge(ADCClock)

      end if;
    end if;
  end Process;

  
end Behavioral;

