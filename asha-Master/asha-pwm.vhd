--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.STD_LOGIC_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! @brief ASHA-Modul - PWM-Signale erzeugen
--! @details  Dieses Modul erzeugt die PWM-Signale fuer PWM-Aktoren
entity AshaPWM is
  Port ( 
    Clock : in std_logic; 									--! Taktsignal
    Reset : in std_logic; 									--! Resetsignal
    EnPWMClock : in std_logic; 								--! Enable-Signal fuer die PWM-Abarbeitung
    PWM1FanInsideValue : in std_logic_vector(7 downto 0); 	--! Signalquellwert Luefter innen
    PWM2FanOutsideValue : in std_logic_vector(7 downto 0);	--! Signalquellwert Luefter aussen
    PWM3LightValue : in std_logic_vector(7 downto 0); 		--! Signalquellwert Licht
    PWM4PeltierValue : in std_logic_vector(7 downto 0); 	--! Signalquellwert Peltier
    PWM1FanInsideSignal : out std_logic; 					--! PWM-Aktorsignal Luefter innen
    PWM2FanOutsideSignal : out std_logic; 					--! PWM-Aktorsignal Luefter aussen
    PWM3LightSignal : out std_logic; 						--! PWM-Aktorsignal Licht
    PWM4PeltierSignal : out std_logic); 					--! PWM-Aktorsignal Peltier
end AshaPWM;

architecture Behavioral of AshaPWM is

signal PWMCounter : unsigned(7 downto 0):= (others => '0'); 
  
begin

    -- Die nachfolgenden Zeilen m�ssen nach der Implementierung von 
    -- PWM_Gen wieder entfernt werden! TODO
	-- PWM1FanInsideSignal<='1';
	-- PWM2FanOutsideSignal<='1';
	-- PWM3LightSignal<='1';
	-- PWM4PeltierSignal<='1';
	-- PWMCounter<=(others=>'0'); 
	
  --! PWM Generierung -> Versuch 7
  -- Hinweis: Die Aktoren sind low-active!


  PWM_Count:Process (EnPWMClock, Reset)
    begin
      if (Reset = '1') then
        PWMCounter <= (others => '0');
      elsif rising_edge(EnPWMClock) then
        if (PWMCounter = 255) then
          PWMCounter <= (others => '0');
        else
          PWMCounter <= PWMCounter + 1;
        end if;
      end if;
    end Process;
  
  PWM_Gen:Process (Clock)
  begin
    -- TODO
    -- Den Innenlüfter einschalten, wenn Counter < als gewünschter PWM-Wert und dieser dabei > 0
    if (PWMCounter <= unsigned(PWM1FanInsideValue) and unsigned(PWM1FanInsideValue) > 0) then
      PWM1FanInsideSignal<='0';
    else
      PWM1FanInsideSignal<='1';
    end if;

    -- Den Außenlüfter einschalten, wenn Counter < als gewünschter PWM-Wert und dieser dabei > 0
    if (PWMCounter <= unsigned(PWM2FanOutsideValue) and unsigned(PWM2FanOutsideValue) > 0) then
        PWM2FanOutsideSignal <= '0';
    else
        PWM2FanOutsideSignal <= '1';
    end if;

    -- Das Licht einschalten, wenn Counter < als gewünschter PWM-Wert und dieser dabei > 0
    if (PWMCounter <= unsigned(PWM3LightValue) and unsigned(PWM3LightValue) > 0) then
        PWM3LightSignal <= '0';
    else
        PWM3LightSignal <= '1';
    end if;

    -- Den Peltier einschalten, wenn Counter < als gewünschter PWM-Wert und dieser dabei > 0
    if (PWMCounter <= unsigned(PWM4PeltierValue) and unsigned(PWM4PeltierValue) > 0) then
        PWM4PeltierSignal <= '0';
    else
        PWM4PeltierSignal <= '1';
    end if;
         
  end Process PWM_Gen; 

end Behavioral;
