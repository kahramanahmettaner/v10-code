library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.AshaTypes.ALL;

entity actor is
    Port ( 
		Clock 				   :	in  std_logic; 			          --! Taktsignal
		Reset 				   :	in  std_logic; 					 	 --! Resetsignal
		Switches 			   : 	in  std_logic_vector(3 downto 0); --! Die acht Schalter
		ButtonsIn 			   :   in  std_logic_vector(3 downto 0);--! Die vier Taster
		SensorVibe 			   : 	in  std_logic;					 	    --! Eingang: Virbationssensor
		SensorDoor 			   : 	in  std_logic; 					    --! Eingang: Tuersensor
		ADCRegister			   :	in  ADCRegisterType; 				 --! Datenregister aller ADC-Werte
		LEDsOut 			      :	out std_logic_vector(5 downto 0);	--! Die acht LEDs
		SevenSegmentValue	   :	out std_logic_vector (15 downto 0);	--! treibt die 7-Segment-Anzeigen
		PWM1FanInsideValue   : 	out std_logic_vector(7 downto 0); 	--! Signalquellwert Luefter innen
		PWM2FanOutsideValue  : 	out std_logic_vector(7 downto 0); 	--! Signalquellwert Luefter aussen
		PWM3LightValue 		: 	out std_logic_vector(7 downto 0);	--! Signalquellwert Licht
		PWM4PeltierValue 	   : 	out std_logic_vector(7 downto 0);	--! Signalquellwert Peltier		
		PeltierDirection 	   : 	out std_logic;						      --! Signalquellwert Peltier	Richtung
		----- Werte von Bluetooth
		LEDsBT 					   :	in std_logic_vector(5 downto 0);	 --! Die acht LEDs
		SevenSegmentValueBT		:	in std_logic_vector (15 downto 0);--! 7SegmentEingang von BT
		PWM1FanInsideValueBT 	:	in std_logic_vector(7 downto 0);	 --! Signalquellwert Luefter innen, von Bt
		PWM2FanOutsideValueBT 	:	in std_logic_vector(7 downto 0);	 --! Signalquellwert Luefter aussen, von Bt
		PWM3LightValueBT 		   :	in std_logic_vector(7 downto 0);	 --! Signalquellwert Licht, von Bt
		PWM4PeltierValueBT		:	in std_logic_vector(7 downto 0);	 --! Signalquellwert Peltier, von Bt
		PeltierDirectionBT		:   in std_logic;						    --! Signalquellwert Peltier Richtung, von Bt
		----- Werte von Regelung
		PWM1FanInsideValueControl	:	in std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen, von Regelung
		PWM2FanOutsideValueControl :	in std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen, von Regelung
		PWM3LightValueControl 		:	in std_logic_vector(7 downto 0); --! Signalquellwert Licht, von Regelung
		PWM4PeltierValueControl		:	in std_logic_vector(7 downto 0); --! Signalquellwert Peltier, von Regelung
		PeltierDirectionControl		:	in std_logic;					      --! Signalquellwert Peltier Richtung, von Regelung
		ControlLightDiffOut 		   :   in unsigned(12 downto 0);		   --! Aktuelle Regeldifferenz Licht
		ControlTempDiffOut  		   :   in unsigned(12 downto 0)		   --! Aktuelle Regeldifferenz Temperatur
	);
end actor;

architecture Behavioral of actor is

-- Zustandsautomat f�r Modus Auswahl
type state_typeM is (Asha1,Asha2,Asha3,
                     SensorRead1,SensorRead2,SensorRead3,
                     ManualActor1,ManualActor2,ManualActor3,
                     AutoActor1,AutoActor2,AutoActor3,
                     Bluetooth1,Bluetooth2,Bluetooth3);--type of state machine(M for Modus).
signal current_m,next_m:state_typeM;--current and next state declaration.

-- Zustandsautomat f�r Sensor Zustaende.
type state_typeS is (Init, Init2, Light, Light2, TempIn, TempIn2, TempOut, TempOut2, Vibe, Vibe2, Door, Door2 );  --type of state machine(S for Sensor).
signal current_s,next_s: state_typeS;  --current and next state declaration.


begin
-- FSM Prozess zur Realisierung der Speicherelemente - Abh�ngig vom Takt den n�chsten Zustand setzen
--> In Versuch 6 zu implementieren!-
FSM_seq: process (Clock,Reset)
	begin
		-- TODO
		if (rising_edge(Clock)) then
			if Reset = '1' then -- reset bringt die FSM in den Startzustand
				current_s <= Init;
				current_m <= Asha2;
			else -- ansonsten wechsle in den nächsten Zustand;
				current_s <= next_s;
				current_m <= next_m;
		end if; 
	end process FSM_seq;
	
-- FSM Prozess (kombinatorisch) zur Realisierung der Modul Zust�nde aus den Typen per Switch Case:  state_typeM
-- Setzt sich aus aktuellem Zustand und folgendem Zustand zusammen: current_m,next_m
--> In Versuch 6-10 zu implementieren
FSM_modul:process(current_m, ButtonsIn(0),ButtonsIn(1))
begin
   -- TODO
   -- Da einige Modi noch nicht implementiert wurde, wird noch nich in diese gewechselt 
   -- sondern es wird nur zw. schon vorhandenen Modin gewechselt
    
   next_m <= current_m;

   case current_m is
		when Asha1 => -- dient als Übergangszustand (rückwärts)
			...
			if (ButtonsIn(1) = '0') then 	-- rückwärts ( Es sollte eig in das Modus4 gewechselt werden. Für jetzt ins Modus1 )
				next_m <= SensorRead3;		
   			end if;
  
		when Asha2 => -- wurde als der eigentliche Zustand implementiert
			...
			if (ButtonsIn(1) = '1') then 		-- rückwärts 
				next_m <= Asha1;
			elsif (ButtonsIn(0) = '1') then 	-- vorwärts 
				next_m <= Asha3;
		   	end if;

		when Asha3 => -- dient als Übergangszustand (vorwärts)
			if (ButtonsIn(0) = '0') then 	-- vorwärts ( Es wird in das Modus1 gewechselt. )
				next_m <= SensorRead2;
		   	end if;

		when SensorRead1 => 
			if (ButtonsIn(1) = '0') then 	-- rückwärts ( Es wird in das Modus1 gewechselt. )
				next_m <= Asha2;		
		   	end if;

		when SensorRead2 => -- wurde als der eigentliche Zustand implementiert
			if (ButtonsIn(1) = '1') then 		-- rückwärts 
				next_m <= Asha1;
			elsif (ButtonsIn(0) = '1') then 	-- vorwärts 
				next_m <= Asha3;
		  	end if;

		when SensorRead3 =>
			if (ButtonsIn(0) = '0') then 	-- vorwärts ( Es wird in das Modus1 gewechselt. )
				next_m <= Asha2; 			--( Es sollte eig in das Modus2 gewechselt werden. Für jetzt in den Startzustand )
		   	end if;

		-- when ManualActor1 => 
		-- when ManualActor2 =>
		-- when ManualActor3 =>
		
		-- when SensorRead1 => 
		-- when SensorRead2 =>
		-- when SensorRead3 =>
		
		-- when AutoActor1 => 
		-- when AutoActor2 =>
		-- when AutoActor3 =>

		-- when Bluetooth1 => 
		-- when Bluetooth2 =>
		-- when Bluetooth3 =>
		
end process;    

-- FSM Prozess (kombinatorisch) zur Realisierung der Ausgangs- und �bergangsfunktionen
	-- Hinweis: 12 Bit ADC-Sensorwert f�r Lichtsensor: 	  ADCRegister(3),
	-- 			12 Bit ADC-Sensorwert f�r Temp. (au�en):  ADCRegister(1),
	-- 			12 Bit ADC-Sensorwert f�r Temp. (innen):  ADCRegister(0),
--> In Versuch 6-10 zu implementieren!-

FSM_comb:process (current_s,current_m, ButtonsIn(2) , ADCRegister, SensorVibe, SensorDoor)
begin
    -- to avoid latches always set current state (Versuch 6)
    next_s <= current_s;
	next_m <= current_m;

    -- Modus 0: "ASHA" Auf 7 Segment Anzeige
    case current_m is
        when Asha1|Asha2|Asha3 => --ASHA state
            LEDsOut<= b"111111";
            SevenSegmentValue <= x"FFFF";
    -- Versuch 6
    -- Modus 1: "Sensorwerte Auslesen"
    -- Durchschalten der Sensoren per BTN2
    -- Ausgabe des ausgewalten Sensors ueber SiebenSegmentAnzeige
    -- when state ... TODO
		when SensorRead1|SensorRead2|SensorRead3 =>
			case current_s is

				-- Startszustand
				when Init =>
					LEDsOut<= b"111111";
					SevenSegmentValue <= x"FFFF";			-- "ASHA" wird 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '1') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= Init2; 
					end if;
				
				when Init2 =>
					LEDsOut <= b"111111";
					SevenSegmentValue <= x"FFFF";			-- "ASHA" wird 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '0') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= Light; 
					end if;

				-- Es wird der Sensorwert zum Lichtssensor gemessen
				when Light =>
					LEDsOut <= b"001000";					-- LD3: Lichtssensor
					SevenSegmentValue <= ADCRegister(3);	-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '1') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= Light2; 
					end if;

				
				when Light2 =>
					LEDsOut <= b"001000";					-- LD3: Lichtssensor
					SevenSegmentValue <= ADCRegister(3);	-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '0') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= TempIn; 
					end if;

				-- Es wird der Sensorwert zum innen Temperatursensor gemessen
				when TempIn =>
					LEDsOut <= b"000100";					-- LD2: Temp innen
					SevenSegmentValue <= ADCRegister(0);	-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '1') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= TempIn2; 
					end if;

				when TempIn2 =>
					LEDsOut <= b"000100";					-- LD2: Temp innen
					SevenSegmentValue <= ADCRegister(0);	-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '0') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= TempOut; 
					end if;

				-- Es wird der Sensorwert zum außen Temperatursensor gemessen
				when TempOut =>
					LEDsOut <= b"000010";					-- LD1: Temp außen
					SevenSegmentValue <= ADCRegister(1);	-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '1') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= TempOut2; 
					end if;

				when TempOut2 =>
					LEDsOut <= b"000010";					-- LD1: Temp außen
					SevenSegmentValue <= ADCRegister(1);	-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '0') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= Vibe; 
					end if;
				
				-- Es wird der Sensorwert zum Vibrationssensor gemessen
				when Vibe =>
					LEDsOut <= b"000001";					-- LD0: Vibrationssensor
					SevenSegmentValue <= SensorVibe;		-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '1') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= Vibe2; 
					end if;

				when Vibe2 =>
					LEDsOut <= b"000001";					-- LD0: Vibrationssensor				
					SevenSegmentValue <= SensorVibe;		-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '0') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= Door; 
					end if;
				
				-- Es wird der Sensorwert zum Doorssensor gemessen
				when Door =>			
					LEDsOut <= b"000000";					-- keine LD: Doorssensor
					SevenSegmentValue <= SensorDoor;		-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '1') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= Door2; 
					end if;

				when Door2 =>
					LEDsOut <= b"000000";					-- keine LD: Doorssensor
					SevenSegmentValue <= SensorDoor;		-- Der Sensorwert wird zu dem 7Segment-Anzegie übergeben
					if (ButtonsIn(2) = '0') then			-- Es wird in den nächsten Zustand gewechselt
						next_s <= Init	; 
					end if;		

                      
    -- Versuch 7
    -- Modus 2: Manuelle Aktorsteuerung	
    -- nur erlauben, wenn keine Regelung aktiv ist!		
        -- when ... TODO
        
    -- Versuch 9
    -- Modus 3: geregelte Aktorsteuerung	
        -- when ... TODO
        
    -- Versuch 10
    -- Modus 4: Steuerung ueber Smartphone-App
            -- when ... TODO
    when others =>
        -- DEFAULT Werte setzen TODO

    end case;
end process;
end Behavioral;
