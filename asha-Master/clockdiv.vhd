library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clockdiv is
    Port ( Clock 			: in std_logic; --! Taktsignal
           Reset 			: in  std_logic; --! Resetsignal
			  En3Hz 			: out std_logic; --! 3Hz-Enable
			  En195Hz 		: out std_logic; --! 195Hz-Enable
			  En6kHz 		: out std_logic; --! 3Hz-Enable
			  EnPWMClock	: out std_logic; --! 3Hz-Enable
			  EnADCClock	: out std_logic  --! ADC-Enable
			  );
end clockdiv;

architecture Behavioral of clockdiv is

  -- Taktfrequenzerzeugung
  signal FreqChangeCounter : unsigned(23 downto 0);
  signal En3HzOld : std_logic;
  signal En195HzOld : std_logic;
  signal En6kHzOld : std_logic;
  signal EnPWMClockOld : std_logic;
  signal EnPWMClockOld2,EnPWMClock2 : std_logic;
  signal EnADCClockOld : std_logic;
   
begin 

clockdivider: Process (Clock)
begin
    if rising_edge(Clock) then

      -- Frequenzen koennen durch einen simplen Zaehler (counter=CTR) 
      -- beliebig um Zweierpotenzen erniedrigt werden. 
      -- Der Quarz des Digilent Zybo Starterkits, und somit das 
      -- ClockIn-Signal, laeuft mit 125MHz. 
      --Nach Frequenzreduzierung zu 50MHZ
      --bei folgenden Bits des 
      -- Zaehlers liegen die entsprechenden Frequenzen an und werden
      -- hier von den entsprechenden Nutzern verwendet:
      -- Bit | Frequenz   | Nutzer                          
      --  0  |  25   MHz  |
      --  1  |  12,5 MHz  | 
      --  2  |   6   MHz  | PWM Regelsystem
      --  3  |   3   MHz  |
      --  4  |   1,5 MHz  |
      --  5  | 781   kHz  |
      --  6  | 390   kHz  |
      --  7  | 195   kHz  |
      --  8  |  97,6 kHz  | ADC-Takt
      --  9  |  48,8 kHz  |
      -- 10  |  24,4 kHz  |
      -- 11  |  12,2 kHz  |
      -- 12  |   6,1 kHz  | LED-Display
      -- 13  |   3,1 kHz  |
      -- 14  |   1,5 kHz  |
      -- 15  | 763   Hz   |
      -- 16  | 381   Hz   |
      -- 17  | 190   Hz   |
      -- 18  |  95   Hz   |
      -- 19  |  48   Hz   |
      -- 20  |  24   Hz   | Lichtregelung
      -- 21  |  12   Hz   |
      -- 22  |   6   Hz   |
      -- 23  |   3   Hz   | Temperaturregelung

      -- Den Frequenzzaehler bei jedem Takt um 1 erhoehen (inkl. Ueberlauf)
      FreqChangeCounter<=FreqChangeCounter+1;

      -- Hier sieht man sehr schoen den Zeit-Charakter von VHDL.
      -- In einer Softwareprogrammiersprache muesste folgende
      -- if-Abfrage _immer_ schief gehen:
      En3HzOld<=FreqChangeCounter(23);
      if (En3HzOld='0') and (FreqChangeCounter(23)='1') then
        -- hier kommt man allerdings bei einer steigenden Signalflanke 
        -- von En3Hz_CTR(23) dennoch in den Abfragekoerper, weil der 
        -- neue Wert fuer En3HzOld erst beim naechsten Takt wieder 
        -- am Ausgang des das En3HzOld speichernden FlipFlops anliegt.
        En3Hz<='1';
      else
        En3Hz<='0';
      end if;

      En195HzOld<=FreqChangeCounter(17);
      if (En195HzOld='0') and (FreqChangeCounter(17)='1') then
        En195Hz<='1';
      else
        En195Hz<='0';
      end if;
		
      En6kHzOld<=FreqChangeCounter(12);
      if (En6kHzOld='0') and (FreqChangeCounter(12)='1') then
        En6kHz<='1';
      else
        En6kHz<='0';
      end if;
		
      EnADCClockOld<=FreqChangeCounter(8);
      if (EnADCClockOld='0') and (FreqChangeCounter(8)='1') then
        EnADCClock<='1';
      else
        EnADCClock<='0';
      end if;
		
      -- PWMTaktEn wird 256 mal durchlaufen, bevor ein PWM-Signal fertig ist.
      -- Das entspricht einer Division durch 256 des PWMTaktEn zum 
      -- resultierenden PWM-Signal, d.h. es gilt folgende Tabelle:
      -- ClockIn direkt: 195 kHz PWM
      --  0 =   98 kHz PWM
      --  1 =   49 kHz PWM
      --  2 =   24 kHz PWM
      --  5 =    3 kHz PWM
      --  6 = 1500 Hz  PWM
      --  7 =  760 Hz  PWM
      --  9 =  190 Hz  PWM
      -- 11 =   48 Hz  PWM
      EnPWMClockOld2<=FreqChangeCounter(5);
      if (EnPWMClockOld2='0') and (FreqChangeCounter(5)='1') then
        EnPWMClock2<='1';
      else
        EnPWMClock2<='0';
      end if;
	
	
	-- (!) ?nderung der originalen EnPWMClock (jetzt: ENPWMClock2), da die nun
	-- langsamere Frequenz f��r eine stabilere Bluetooth-Verbindung sorgt
	  EnPWMClockOld<=FreqChangeCounter(11);
      if (EnPWMClockOld='0') and (FreqChangeCounter(11)='1') then
        EnPWMClock<='1';
      else
        EnPWMClock<='0';
      end if;

    end if; -- CLK'event and CLK = '1' 
  end Process;
  
  end Behavioral;

