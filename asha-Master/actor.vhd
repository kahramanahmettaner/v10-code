library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.AshaTypes.ALL;

entity actor is
	Port (
		Clock : in std_logic; --! Taktsignal
		Reset : in std_logic; --! Resetsignal
		Switches : in std_logic_vector(3 downto 0); --! Die acht Schalter
		ButtonsIn : in std_logic_vector(3 downto 0); --! Die vier Taster
		SensorVibe : in std_logic; --! Eingang: Virbationssensor
		SensorDoor : in std_logic; --! Eingang: Tuersensor
		ADCRegister : in ADCRegisterType; --! Datenregister aller ADC-Werte
		LEDsOut : out std_logic_vector(5 downto 0); --! Die acht LEDs
		SevenSegmentValue : out std_logic_vector (15 downto 0);--! treibt die 7-Segment-Anzeigen
		PWM1FanInsideValue : out std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen
		PWM2FanOutsideValue : out std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen
		PWM3LightValue : out std_logic_vector(7 downto 0); --! Signalquellwert Licht
		PWM4PeltierValue : out std_logic_vector(7 downto 0); --! Signalquellwert Peltier
		PeltierDirection : out std_logic; --! Signalquellwert Peltier Richtung
		----- Werte von Bluetooth
		LEDsBT : in std_logic_vector(5 downto 0); --! Die acht LEDs
		SevenSegmentValueBT : in std_logic_vector (15 downto 0); --! 7SegmentEingang von BT
		PWM1FanInsideValueBT : in std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen, von Bt
		PWM2FanOutsideValueBT : in std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen, von Bt
		PWM3LightValueBT : in std_logic_vector(7 downto 0); --! Signalquellwert Licht, von Bt
		PWM4PeltierValueBT : in std_logic_vector(7 downto 0); --! Signalquellwert Peltier, von Bt
		PeltierDirectionBT : in std_logic; --! Signalquellwert Peltier Richtung, von Bt
		----- Werte von Regelung
		PWM1FanInsideValueControl : in std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen, von Regelung
		PWM2FanOutsideValueControl : in std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen, von Regelung
		PWM4PeltierValueControl : in std_logic_vector(7 downto 0); --! Signalquellwert Peltier, von Regelung
		PeltierDirectionControl : in std_logic; --! Signalquellwert Peltier Richtung, von Regelung
		ControlLightDiffOut : in unsigned(12 downto 0); --! Aktuelle Regeldifferenz Licht
		ControlTempDiffOut : in unsigned(12 downto 0) --! Aktuelle Regeldifferenz Temperatur
	);
end actor;

architecture Behavioral of actor is
-- Zustandsautomat für Modus Auswahl
type state_typeM is (Asha1,Asha2,Asha3,
					SensorRead1,SensorRead2,SensorRead3,
					ManualActor1,ManualActor2,ManualActor3,
					AutoActor1,AutoActor2,AutoActor3,
					Bluetooth1,Bluetooth2,Bluetooth3); --type of state machine(M for Modus).

signal current_m,next_m:state_typeM;	--current and next state declaration.

-- Zustandsautomat für Sensor Zustaende.
type state_typeS is (Init, Init2, Light, Light2, TempIn, TempIn2, TempOut, TempOut2, Vibe, Vibe2, Door, Door2 ); --type of state machine(S for Sensor).
signal current_s,next_s: state_typeS; --current and next state declaration.

-- Zustandsautomat für Seventsegmentanzeige bei Aktorsteuerung
type state_typeActor7seg is (InitA1, InitA2, LightA1, LightA2, TempA1, TempA2);  
signal current_actor7seg, next_actor7seg: state_typeActor7seg;

begin
-- FSM Prozess zur Realisierung der Speicherelemente - Abhängig vom Takt den nächsten Zustand setzen
--> In Versuch 6 zu implementieren!-
FSM_seq: process (Clock,Reset)
begin
	if(Reset='1') then --Beim Reset Signal
		current_m<=Asha1; --den Zustand fÃ¼r den Modus zurÃ¼cksetzen auf Asha1
		current_s<=Init; --und den Zustand fÃ¼r den gewÃ¤hlten Sensor auf Init setzen (relevant fÃ¼r Modus 1)
	end if;
	
	if(rising_edge(Clock)) then --Bei jedem Clock Signal
		current_m<=next_m; --den Zustand fÃ¼r den Modus aktuallisieren
		current_s<=next_s;
	end if; --und den Zustand fÃ¼r den gewÃ¤hlten Sensor aktuallisieren (relevant fÃ¼r Modus 1)
end process FSM_seq;

-- FSM Prozess (kombinatorisch) zur Realisierung der Modul Zustände aus den Typen per Switch Case: state_typeM
-- Setzt sich aus aktuellem Zustand und folgendem Zustand zusammen: current_m,next_m
--> In Versuch 6-10 zu implementieren
FSM_modul:process(current_m, ButtonsIn(0),ButtonsIn(1))
begin
	next_m <= current_m;
	case current_m is
		when Asha2 =>
			if (ButtonsIn(0)='1') then
 				next_m <= Asha3;
 			elsif (ButtonsIn(1)='1') then
 				next_m <= Asha1;
 			end if;

		when SensorRead2 =>
			if (ButtonsIn(0)='1') then
			next_m <= SensorRead3;
			elsif (ButtonsIn(1)='1') then
			next_m <= SensorRead1;
			end if;

		when ManualActor2 =>
			if (ButtonsIn(0)='1') then
				next_m <= ManualActor3;
			elsif (ButtonsIn(1)='1') then
				next_m <= ManualActor1;
			end if;

		when AutoActor2 =>
			if (ButtonsIn(0)='1') then
				next_m <= AutoActor3;
			elsif (ButtonsIn(1)='1') then
				next_m <= AutoActor1;
			end if;

		when Bluetooth2 =>
			if (ButtonsIn(0)='1') then
				next_m <= Bluetooth3;
			elsif (ButtonsIn(1)='1') then
				next_m <= Bluetooth1;
			end if;			

		when Asha1 =>
			if (ButtonsIn(1)='0') then
				next_m <= Bluetooth2;
			end if;

		when Asha3 =>
			if (ButtonsIn(0)='0') then
				next_m <= SensorRead2;
			end if;

		when SensorRead1 =>
			if (ButtonsIn(1)='0') then
				next_m <= Asha2;
			end if;
		when SensorRead3 =>
			if (ButtonsIn(0)='0') then
				next_m <= ManualActor2;
			end if;

		when ManualActor1 =>
			if (ButtonsIn(1)='0') then
				next_m <= SensorRead2;
			end if;

		when ManualActor3 =>
			if (ButtonsIn(0)='0') then
				next_m <= AutoActor2;
			end if;

		when AutoActor1 =>
			if (ButtonsIn(1)='0') then
				next_m <= ManualActor2;
			end if;

		when AutoActor3 =>
			if (ButtonsIn(0)='0') then
				next_m <= Bluetooth2;
			end if;

		when Bluetooth1=>
			if (ButtonsIn(1)='0') then
				next_m <= AutoActor2;
			end if;

		when Bluetooth3 =>
			if (ButtonsIn(0)='0') then
				next_m <= Asha2;
			end if;

 	end case;
end process;

-- FSM Prozess (kombinatorisch) zur Realisierung der Ausgangs- und Übergangsfunktionen
-- Hinweis: 12 Bit ADC-Sensorwert für Lichtsensor: ADCRegister(3),
-- 12 Bit ADC-Sensorwert für Temp. (außen): ADCRegister(1),
-- 12 Bit ADC-Sensorwert für Temp. (innen): ADCRegister(0),
--> In Versuch 6-10 zu implementieren!-
FSM_comb:process (current_s,current_m, ButtonsIn(2) , ADCRegister, SensorVibe, SensorDoor)
begin
 	-- to avoid latches always set current state (Versuch 6)
 	next_s <= current_s;
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
		when SensorRead1|SensorRead2|SensorRead3 => --Modus 1: Sensoren auslesen
			LEDsOut(5 downto 4)<= "00";
            
            -- Wenn Button(2) gedr�ckt wird, wird in den �bergangszustand gewechselt
			if(ButtonsIn(2)='1') then 
				case current_s is
					when Init =>   -- Init 
						next_s <= Init2;
						LEDsOut(3 downto 0)<= "0000"; -- LEDs anpassen
					when Init2 =>   -- Init
						next_s <= Init2;
						LEDsOut(3 downto 0)<= "0000"; -- LEDs anpassen
					when Light =>   -- Lichtssensor
						next_s <= Light2;
						LEDsOut(3 downto 0)<= "1000"; -- LEDs anpassen
					when Light2 =>  -- Lichtssensor 
						next_s <= Light2;
						LEDsOut(3 downto 0)<= "1000"; -- LEDs anpassen
					when TempIn =>  -- Temperatursensor innen
						next_s <= TempIn2;
						LEDsOut(3 downto 0)<= "0100"; -- LEDs anpassen
					when TempIn2 => -- Temperatursensor innen
						next_s <= TempIn2;
						LEDsOut(3 downto 0)<= "0100"; -- LEDs anpassen
					when TempOut => -- Temperatursensor au�en
						next_s <= TempOut2;
						LEDsOut(3 downto 0)<= "0010"; -- LEDs anpassen
					when TempOut2 => -- Temperatursensor au�en
						next_s <= TempOut2;
						LEDsOut(3 downto 0)<= "0010"; -- LEDs anpassen
					when Vibe =>   -- Vibrationssensor
						next_s <= Vibe2;
						LEDsOut(3 downto 0)<= "0001"; -- LEDs anpassen
					when Vibe2 =>  -- Vibrationssensor
						next_s <= Vibe2;
						LEDsOut(3 downto 0)<= "0001"; -- LEDs anpassen
					when Door =>   -- Doorssensor
						next_s <= Door2;
						LEDsOut(3 downto 0)<= "0000"; -- LEDs anpassen
					when Door2 => -- Doorssensor
						next_s <= Door2;
						LEDsOut(3 downto 0)<= "0000"; -- LEDs anpassen
				end case;
			end if;

            -- Wenn Button(2) im �bergangszustand losgelassen wird, wird in den n�chsten Zustand gewechselt
			if(ButtonsIn(2)='0') then
				case current_s is
					when Init => 
						next_s <= Init;
						SevenSegmentValue <= X"ffff";
						LEDsOut(3 downto 0) <= b"1010";
					when Init2 => 
						next_s <= Light;
					
					when Light =>
						next_s <= Light;
						SevenSegmentValue <= X"0" & ADCRegister(3);
						LEDsOut(3 downto 0) <= b"1000";
					when Light2 => 
						next_s <= TempIn;
					
					when TempIn => 
						next_s <= TempIn;
						SevenSegmentValue <= X"0" & ADCRegister(0);
						LEDsOut(3 downto 0) <= b"0100";
					when TempIn2 => 
						next_s <= TempOut;
					
					when TempOut => 
						next_s <= TempOut;
						SevenSegmentValue <= X"0" & ADCRegister(1);
						LEDsOut(3 downto 0) <= b"0010";
					when TempOut2 => 
						next_s <= Vibe;
					
					when Vibe => 
						next_s <= Vibe;
						SevenSegmentValue <= b"000000000000000" & SensorVibe;
						LEDsOut(3 downto 0) <= b"0001";
					when Vibe2 => 
						next_s <= Door;
					
					when Door => 
						next_s <= Door;
						SevenSegmentValue <= b"000000000000000" & SensorDoor;
						LEDsOut(3 downto 0) <= b"0000";
					when Door2 => 
						next_s <= Init;
				end case;
			end if;
		
 -- Versuch 7
 -- Modus 2: Manuelle Aktorsteuerung
 -- nur erlauben, wenn keine Regelung aktiv ist!
 -- when ... TODO
		when ManualActor1|ManualActor2|ManualActor3 =>
			LEDsOut(5 downto 4)<= "01";
			-- LEDsOut(3 downto 0)<= "0101";
			
			if (Switches(0) = '1') then
				PWM1FanInsideValue <= b"11111111"; -- Innenl�fter auf 100%
			else
				PWM1FanInsideValue <= b"00000000"; -- Innenl�fter aus
			end if;

			if (Switches(1) = '1') then
				PWM2FanOutsideValue <= b"11111111"; --Au�enl�fter auf 100%
			else
				PWM2FanOutsideValue <= b"00000000"; --Au�enl�fter aus
			end if;

			if (Switches(2) = '1') then
				PWM3LightValue <= b"11111111"; --Licht auf 100%
			else
				PWM3LightValue <= b"00000000"; --Licht aus
			end if;

			if (Switches(3) = '1') then
				PWM4PeltierValue <= b"11111111"; --Peltier auf 100%
				PeltierDirection <= '1'; --Peltier auf Heizen
			else
				PWM4PeltierValue <= b"00000000"; --Peltier aus
				PeltierDirection <= '1'; --Peltier auf Heizen
			end if;
			
 -- Versuch 9
 -- Modus 3: geregelte Aktorsteuerung
 -- when ... TODO
		when AutoActor1|AutoActor2|AutoActor3 =>
			LEDsOut(5 downto 4)<= "10";
			LEDsOut(3 downto 0)<= "0000";
		
			if(Switches(3) = '0') then -- SW3 aus
				if(Switches(0) = '1' and Switches(1) = '0') then -- LightDiff
					SevenSegmentValue <= (others => '0');  
					SevenSegmentValue(11 downto 0) <= std_logic_vector(ControlLightDiffOut(11 downto 0)); 
				elsif (Switches(1) = '1' and Switches(0) = '0') then -- TempDiff
					SevenSegmentValue <= (others => '0');  
					SevenSegmentValue(12 downto 0) <= std_logic_vector(ControlTempDiffOut); 
				elsif (Switches(1) = '0' and Switches(0) = '0') then
					SevenSegmentValue <= (others => '0');  
				else
					next_actor7seg <= current_actor7seg;
					
					-- es wird durch Drücken von Button2 geändert, welcher Sensorwert angezeigt wird
					case current_actor7seg is

						-- Startzustand
						when InitA1 =>
							SevenSegmentValue <= (others => '0');  
							if(ButtonsIn(2) = '1') then
								next_actor7seg <= InitA2;
							end if;
						when InitA2 =>
							if(ButtonsIn(2) = '0') then
								next_actor7seg <= LightD1;
							end if;
					
						-- Licht
						when LightA1 =>
							SevenSegmentValue <= (others => '0');  
							SevenSegmentValue(11 downto 0) <= std_logic_vector(ControlLightDiffOut(11 downto 0));
							if(ButtonsIn(2) = '1') then
								next_actor27seg <= LightA2;
							end if;
						when LightA2 =>
							SevenSegmentValue <= (others => '0');  
							SevenSegmentValue(11 downto 0) <= std_logic_vector(ControlLightDiffOut(11 downto 0)); 
							if(ButtonsIn(2) = '0') then
								next_actor7seg <= TempA1;
							end if;
						
						-- Temperatur
						when TempA1 =>
							SevenSegmentValue <= (others => '0');  
							SevenSegmentValue(12 downto 0) <= std_logic_vector(ControlTempDiffOut);
							if(ButtonsIn(2) = '1') then
								next_actor7seg <= TempA2;
							end if;
						when TempA2 =>
							SevenSegmentValue <= (others => '0');  
							SevenSegmentValue(12 downto 0) <= std_logic_vector(ControlTempDiffOut);
							if(ButtonsIn(2) = '0') then
								next_actor7seg <= InitA1;
							end if;
						
						when others => null;

					end case;
				end if;

			else -- SW3 an:
				if(Switches(0) = '1') then -- Licht
					PWM3LightValue <= PWM3LightValueControl;
				else
					PWM3LightValue <= (others => '0');
				end if;
				if(Switches(2) = '1') then
					if(Switches(1) = '1') then -- Lüfter außen
						PWM2FanOutsideValue <= PWM2FanOutsideValueControl;
					else
						PWM2FanOutsideValue <=  (others => '0');
					end if;
					
				else
					if(Switches(1) = '1') then -- Lüfter innen
						PWM1FanInsideValue <= PWM1FanInsideValueControl;
					else
						PWM1FanInsideValue <=  (others => '0');
					end if;
				end if;
			end if;

 -- Versuch 10
 -- Modus 4: Steuerung ueber Smartphone-App
 -- when ... TODO
		when Bluetooth1|Bluetooth2|Bluetooth3 =>
			LEDsOut(5 downto 4)<= "11";
			LEDsOut(3 downto 0)<= "0101";

			--LEDsBT : in std_logic_vector(5 downto 0); --! Die acht LEDs
			--SevenSegmentValueBT : in std_logic_vector (15 downto 0); --! 7SegmentEingang von BT
			--PWM1FanInsideValueBT : in std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen, von Bt
			--PWM2FanOutsideValueBT : in std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen, von Bt
			--PWM3LightValueBT : in std_logic_vector(7 downto 0); --! Signalquellwert Licht, von Bt
			--PWM4PeltierValueBT : in std_logic_vector(7 downto 0); --! Signalquellwert Peltier, von Bt
			--PeltierDirectionBT : in std_logic; --! Signalquellwert Peltier Richtung, von Bt

			-- einen festen Wert vorgeben:
			PeltierDirection <= '1'; -- auf Heizen
			PWM4PeltierValue <= b"11111111"; -- 100%

			-- Werte von BT übergeben:
			-----------
			-- Aktoren:
			PWM1FanInsideValue <= PWM1FanInsideValueBT; -- b"00000000"; -- Innenl�fter aus
			PWM2FanOutsideValue <= PWM2FanOutsideValueBT; -- b"11111111"; --Au�enl�fter auf 100%
			PWM3LightValue <= PWM3LightValueBT; -- b"11111111"; --Licht auf 100%
			PWM4PeltierValue <= PWM4PeltierValueBT; -- b"11111111"; --Peltier auf 100%
			PeltierDirection <= PeltierDirectionBT; -- '1'; --Peltier auf Heizen
			
			-- Sensoren:
			SevenSegmentValue <= SevenSegmentValueBT;
			LEDsOut <= LEDsBT;
		
			--when Light =>
			--			SevenSegmentValue <= X"0" & ADCRegister(3);
			--			LEDsOut(3 downto 0) <= b"1000";
			--		when TempIn => 
			--			SevenSegmentValue <= X"0" & ADCRegister(0);
			--			LEDsOut(3 downto 0) <= b"0100";
			--		when TempOut => 
			--			SevenSegmentValue <= X"0" & ADCRegister(1);
			--			LEDsOut(3 downto 0) <= b"0010";
			--		when Vibe => 
			--			SevenSegmentValue <= b"000000000000000" & SensorVibe;
			--			LEDsOut(3 downto 0) <= b"0001";
			--		when Door => 
			--			SevenSegmentValue <= b"000000000000000" & SensorDoor;
			--			LEDsOut(3 downto 0) <= b"0000";
				
 when others =>
 -- DEFAULT Werte setzen TODO
 end case;
end process;
end Behavioral;