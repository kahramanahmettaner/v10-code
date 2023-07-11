--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.std_logic_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! @brief 8bit CRC-16 CCITT MCRF4XX (Cyclic Redundancy Check)
--! @details
--! Features:
--!  - CRC-16 mit CCITT-Polynom (x^16+x^12+x^5+1)
--!    - LSB-First (0x1021-Polynom, nicht 0x8408), reflected/reversed
--!    - Initialisierung: 0xFFFF
--!  - Byteweise CRC-Berechnung
entity AshaCRC16 is
    Port ( Clock : in std_logic; --! Taktsignal
           Reset : in  std_logic; --! Resetsignal
           NextData : in  std_logic; --! Sendeanweisung (1 Takt)
           InByte  : in  std_logic_vector (7 downto 0); --! Dateneingang
           CRCOut : out  std_logic_vector (15 downto 0)); --! CRC-Ausgang
end AshaCRC16;

--! @brief 8bit CRC-16 CCITT MCRF4XX (Cyclic Redundancy Check)
--! @details Nach dem Reset wird ein im Quelltext festgelegter Startwert
--! angenommen (im CRCOut), welcher z.B. den Startdelimiter schon enthalten 
--! kann. Bei jedem High von NextData (bitte nur einen Takt lang) wird nun 
--! der Wert von InByte dem CRCOut hinzugefuegt. Dies geschieht vom 
--! niederwertigsten Bit aus (LSB-first) in 8 Takten.
architecture Behavioral of AshaCRC16 is

signal Data : std_logic_vector(7 downto 0); --! interner Datenpuffer 
signal CRC : std_logic_vector(0 to 15); --! internes CRC-Register
signal Counter : unsigned( 2 downto 0); --! counter: Byte -> bitweise Umsetzung
signal Old15, Running : std_logic; --! Zwischenspeicher 16.Bit, Puffern des NextData

begin

  Old15 <= Data(to_integer(Counter)) xor CRC(15); 
  CRCOut<=CRC;

  --! CRC Behandlung per Schieberegister
  process (Clock)
  begin
    if rising_edge(Clock) then
      if (Reset='1') then
        -- Startwert: 0xFFFF xor (CRC-16 des verdrehten Startdelimiters)
        CRC<="1101001111111101"; 
        -- Dieser ist notwendig, da am Mikrocontroller der CRC von Anfang an 
        -- nicht ueber AF05[Restliches-Paket] gebildet wurde, sondern ueber
        -- 05AF[Restliches-Paket]. 
        Counter<="000";
        Running<='0';
		
      -- Neue Daten annehmen, wenn diese kommen, waehrend man nicht gerade
      -- alte bearbeitet
      elsif (Running='0') and (NextData='1') then 
        Data<=InByte;
        Counter<="000";
        Running<='1'; -- Setzen, dass CRC-Berechnung gerade laeuft.
      elsif (Running='1') then 

        -- Register shiften
        CRC(15)<= CRC(14);
        CRC(14)<= CRC(13);
        CRC(13)<= CRC(12);
        CRC(12)<= CRC(11) xor Old15;
        CRC(11)<= CRC(10);
        CRC(10)<= CRC(9);
        CRC(9) <= CRC(8);
        CRC(8) <= CRC(7);
        CRC(7) <= CRC(6);
        CRC(6) <= CRC(5);
        CRC(5) <= CRC(4) xor Old15;
        CRC(4) <= CRC(3);
        CRC(3) <= CRC(2);
        CRC(2) <= CRC(1);
        CRC(1) <= CRC(0);
        CRC(0) <= Old15;
        -- Bit 0,5 und 12 werden mit Bit 16 (dem alten Bit 15) 
        -- verentwederodert. 
        
        if (Counter="111") then
          Running<='0'; -- CRC-Berechnung fuer dieses Byte ist durch
        end if;
        Counter<=Counter+1; -- im naechsten Takt nachstes Bit nehmen
      end if;
    end if;
  end process;

end Behavioral;

