--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.std_logic_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! @brief Ansteuerung der Siebensegmentanzeige
--! @details Dieses Modul uebernimmt Daten in Form eines 16-bit Wortes und 
--! zeigt dieses in Form des Hex-Wertes auf der Siebensegmentanzeige an
entity AshaSiebensegment is
    Port (Clock : in std_logic; 					--! Taktsignal
          Reset : in  std_logic; 					--! Resetsignal
          EnSevenSegmentClock : in std_logic; 						--! Enable-Signal des Treiberprozesses
		      EnSevenSegmentSlowClock : in std_logic; 					--! Enable-Signal fr Aktualisierung der Anzeige
          SevenSegmentValue : in std_logic_vector (15 downto 0); 	--! der Wert, der auf der Anzeige erscheinen soll
          SevenSegment : out std_logic_vector(31 downto 0); --! treibt die 7-Segment-Anzeigen; alle, bei denen AN aktiviert ist
           		
          -- Clock3Hz von clockdiv, damit die einzelnen Werte der Siebensegmentanzeige langsamer wechseln
		      Clock3Hz : in std_logic
          );		
end AshaSiebensegment;

--! Ansteuerung der Siebensegmentanzeige
architecture Behavioral of AshaSiebensegment is

-- wird mit Clock3Hz geändert damit die Werte lesbarer sind
signal currentSevenSegmentValue : std_logic_vector (15 downto 0) := SevenSegmentValue;

-- Ziffer nach SevenSegment Konvertierung
-- Die Eingaenge der Siegensegmentanzeige sind low-active
type SevenSegmentset_type is array (0 to 15) of std_logic_vector(7 downto 0);

constant SevenSegmentset : SevenSegmentset_type := (
---- 7-Segment Anzeige Anordnung----
--      A
--     ---
--  F |   | B
--     -G-
--  E |   | C
--     ---
--      D
 -- Versuch 6:
 -- Die Zeichen 2 bis F muessen hier noch richtig definert werden, in dem die entsprechenden Bits f�r die oben gezeichnete 7 Segment Anzeige gesetzt werden.
 -- Wenn Sie weitere Unterlagen ben�tigen, ben�tigen, schauen Sie sich die Library f�r Arduino unter dieser Adresse an: https://github.com/avishorp/TM1637
 -- XGFEDCBA
  b"00111111", -- 0
  b"00000110", -- 1 TODO
  b"01011011", -- 2
  b"01001111", -- 3
  b"01100110", -- 4
  b"01101101", -- 5
  b"01111101", -- 6
  b"00000111", -- 7
  b"01111111", -- 8
  b"01101111", -- 9
  b"01110111", -- A
  b"01111100", -- b
  b"00111001", -- C
  b"01110001", -- d
  b"00000000", -- E
  b"00000000"  -- F
  );


begin

  UpdateValue: process (Clock3Hz)
  begin
    if rising_edge(Clock3Hz) then
      currentSevenSegmentValue <= SevenSegmentValue;
    end if;
  end process;   

 SetSevenSegment: Process (Clock, Reset) -- 7-Segment-Prozess
 begin
	if (Reset = '1') then
		SevenSegment <= x"00000000";
    elsif rising_edge(Clock) then
		-- TODO--
		-- Die Werte in SevenSegment werden mit der SevenSegment Clock geschrieben und bei schnellen �nderungen der Werte, lassen sich diese nicht lesen!
		-- �ndern Sie den Code so, dass die Wiederholrate der Siebensegmentanzeige gleich bleibt und sich nur die Werte langsamer  bei einer Frequenz von 3 Hz �ndern!
		if EnSevenSegmentClock = '1' then
			if (currentSevenSegmentValue = x"FFFF") then -- Zur Darstellung "ASHA" bei dem eigentlichen Wert von "FFFF"
					 SevenSegment(15 downto 8)  <= b"01101101"; -- S
					 SevenSegment(23 downto 16) <= b"01110110"; -- H
					 SevenSegment(31 downto 24) <= b"01110111"; -- A
					 SevenSegment(7 downto 0)   <= b"01110111"; -- A
			else	-- Darstellung der Zeichen
					 SevenSegment(23 downto 16) <= SevenSegmentset(to_integer(unsigned(currentSevenSegmentValue(7 downto 4))));
					 SevenSegment(15 downto 8) <= SevenSegmentset(to_integer(unsigned(currentSevenSegmentValue(11 downto 8))));
					 SevenSegment(7 downto 0) <= SevenSegmentset(to_integer(unsigned(currentSevenSegmentValue(15 downto 12))));
					 SevenSegment(31 downto 24) <= SevenSegmentset(to_integer(unsigned(currentSevenSegmentValue(3 downto 0))));
			end if;
		end if; -- EnSevenSegmentClock
    end if; -- Clock
end Process SetSevenSegment;

end Behavioral;


