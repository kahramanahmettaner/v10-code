--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.STD_LOGIC_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! @brief ASHA-Modul - Signale des Vibrationssensors aufbereiten
--! @details Dieses Modul Empfaengt das Signal des Vibrationssensors im Haus 
--! und wertet es aus. Ueber das Signal SensorVibeHouseOn kann dieses Modul
--! dem Hauptmodul signalisieren, wenn es das Haus auschalten soll. 

entity AshaVibe is
  Port ( 
    Clock : in std_logic; 				--! Taktsignal
    Reset : in std_logic; 				--! Resetsignal
    SensorVibe : in std_logic; 			--! Vibrationssensorsignal direkt vom Haus
    SensorVibeHouseOn : out std_logic); --! Haus an/aus-Signal des Vibe-Moduls
end AshaVibe;

architecture Behavioral of AshaVibe is

  signal SensorVibeOld : std_logic; 	--! Speicherregister fuer alten Sensorzustand 
  
 begin

  --folgende Zeile l�schen, wenn Vibe_Detect implementiert ist!
  -- SensorVibeHouseOn <= '1';

  --! Realisierung des Vibrationsdetektors, Versuch 7
  Vibe_Detect:Process (Clock) -- Vibrationsdetektor
  begin
    if rising_edge(Clock) then
        -- TODO
        -- Bei einer Erschütterung wird der Ausgang so gesetzt, dass das Haus ausgeschalt wird
        if (SensorVibe = '0') then
            SensorVibeHouseOn <= '0';
      
        -- Beim Reset wird der Ausgang zurückgesetzt  
        elsif (Reset = '1') then
            SensorVibeHouseOn <= '1'; 
        end if;
    end if;
  end Process Vibe_Detect; -- Vibrationsdetektor

end Behavioral;
