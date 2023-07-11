----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:39:56 02/17/2014 
-- Design Name: 
-- Module Name:    bluetooth - Behavioral 

----------------------------------------------------------------------------------

--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.std_logic_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! Projektdaten
library work;
--! Vordefinierte Arrays des Projektes
use work.AshaTypes.ALL;

entity bluetooth is
  Port(
			  -- Memory Access - DI=DeviceInfo DN=DeviceName
			RXData : in std_logic_vector(7 downto 0); 		-- received char
			TXData : out std_logic_vector(7 downto 0); 		-- char to send
			Ready2Send : in std_logic;						-- ready to send new char
			DoWrite : out std_logic; 						-- set to send new char
			DIMemAddr : out std_logic_vector(5 downto 0); 	-- Adresse ganzes Payload
			DIMemData : in std_logic_vector(82 downto 0); 	-- Payload 5-13 + 11 i2c-Addr.bits
			DNMemAddr : out std_logic_vector(11 downto 0); 
			DNMemData : in std_logic_vector(7 downto 0);	-- Ein Byte des Namens
			ClockIn : in  std_logic;
			RxFin : in std_logic;
			Reset	: in std_logic;
			CRCInReset	: out std_logic;
			CRCOutReset : out std_logic;
			DoCRCIn	: out std_logic;
			DoCRCOut	: out std_logic;
			LEDsOut : out std_logic_vector(5 downto 0); 	--! Die acht LEDs
			Buttons : in std_logic_vector(3 downto 0); 		--! debounced buttons
			Switches : in  std_logic_vector(3 downto 0); 		--! Die acht Schalter
			SevenSegmentValueOut : out std_logic_vector (15 downto 0); 	-- Eingang der 7SegAnzeige
			ADCRegister	:	in  ADCRegisterType; 			--! Datenregister aller ADC-Werte
			SensorDoor :  in  std_logic;				    --! Eingang: Tuersensor
			PWM1FanInsideValue 	:	in std_logic_vector(7 downto 0); 	 --! Signalquellwert Luefter innen
			PWM2FanOutsideValue 	:	in std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen
			PWM3LightValue 		:	in std_logic_vector(7 downto 0); 	 --! Signalquellwert Licht
			PWM4PeltierValue		:	in std_logic_vector(7 downto 0); --! Signalquellwert Peltier
			PeltierDirection		:  in std_logic;
			PWM1FanInsideValueOut 	:	out std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen
			PWM2FanOutsideValueOut 	:	out std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen
			PWM3LightValueOut 		:	out std_logic_vector(7 downto 0); --! Signalquellwert Licht
			PWM4PeltierValueOut		:	out std_logic_vector(7 downto 0); --! Signalquellwert Peltier			
			PeltierDirectionOut		:  out std_logic;
			BTHouseOn				: 	out std_logic;
			ControlTempDiff		:  in unsigned(12 downto 0);
			ControlLightDiff		:	in unsigned(12 downto 0);
			ControlTempTargetOut		:	out unsigned(11 downto 0);
			ControlLightTargetOut	:	out unsigned(11 downto 0);
			ControlTemp				:	out std_logic;
			ControlLight			:	out std_logic;
			CRCIn  : in std_logic_vector(15 downto 0);
			CRCOut : in std_logic_vector(15 downto 0)
		);   

end bluetooth;

architecture Behavioral of bluetooth is

  -- Protokollspeichervariablen
  signal CommandIn, CommandOut : std_logic_vector(8 downto 0);
  signal PacketFull,PacketSent,SendPacket,GetValue,SetValue : std_logic;
  type PacketData_type is array (4 to 13) of std_logic_vector(7 downto 0);--PacketData(4-13),????8bit
  signal PacketDataIn, PacketDataOut: PacketData_type;
  
  -- Pseudozustandmaschinen
  signal RxState : unsigned(3 downto 0);
  signal TxState : unsigned(3 downto 0);
  
  -- CRC Generierung
  signal CRCValueReceived : std_logic_vector(15 downto 0);
 
  -- Spezialbehandlung im Sender, wenn ein Name gesendet wird
  signal SendName : std_logic;

  -- Anlegen der Registeradresse in der Protokollbehandlung--?????????????
  signal ADCRegisterIndex : integer range 0 to 7;
  
  signal InternalHouseOn: std_logic;
  signal LEDs	: std_logic_vector(5 downto 0); --! Die acht LEDs
  signal SevenSegmentValue  : std_logic_vector (15 downto 0); 	-- 7SegAnzeige
  signal ControlTempTarget		:	unsigned(11 downto 0);
  signal ControlLightTarget	:	unsigned(11 downto 0);
  signal PWM1FanInsideValueFix 	: std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen
  signal PWM2FanOutsideValueFix 	: std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen
  signal PWM3LightValueFix 	: std_logic_vector(7 downto 0); --! Signalquellwert Licht
  signal PWM4PeltierValueFix		: std_logic_vector(7 downto 0); --! Signalquellwert Peltier			
  signal PeltierDirectionFix		: std_logic;
  signal ControlLightInt	:	std_logic;
  signal ControlTempInt		:	std_logic;
  

begin
DIMemAddr<=PacketDataIn(4)(5 downto 0);
BTHouseOn<=InternalHouseOn;
LEDsOut<=LEDs;
SevenSegmentValueOut<=SevenSegmentValue;
ControlTempTargetOut<=ControlTempTarget;
ControlLightTargetOut<=ControlLightTarget;
PWM1FanInsideValueOut<=PWM1FanInsideValueFix;
PWM2FanOutsideValueOut<=PWM2FanOutsideValueFix;
PWM3LightValueOut<=PWM3LightValueFix;
PWM4PeltierValueOut<=PWM4PeltierValueFix;
PeltierDirectionOut<=PeltierDirectionFix;
ControlLight<=ControlLightInt;
ControlTemp<=ControlTempInt;
---------------------------------------------------------------------
--! Namen zurechtlegen
  -- An den DeviceName-Speicher wird permanent die Adresse laut 
  -- eintreffendem Paket gelegt.
  -- Die Adresse ist hierbei von der Sensornummer und dem aktuellen 
  -- Status des Sendeprozesses abhaengig. 
  --?????????????????????
  Process (PacketDataOut(4), TxState, PacketDataOut(5)) -- Namen zurechtlegen--????????
  begin
    -- Adresse ist 14 bit breit
    -- 64 Bytes pro Sensor (6 Adressbits)
    -- fuer 256 Sensoren (8 Adressbits)
    -- Obere 8 bit fuer den Sensor, untere 6 bit fuer das Byte
    -- Die Byteadresse errechnet sich aus dem NameOffset und dem TxState
    -- TxState ist die Byte-Position im Paket
    -- Da diese neu gesetzt wird, direkt nachdem der aktuelle Zustand seine 
    -- Daten zum Uart ubermittelt, bleibt bei Aenderung genuegend Zeit (=Take),
    -- bis das naechste Mal der neue Wert im Sender benoetigt wird.
    -- NameOffset ist die Position des Strings im Paket relativ zum ersten Byte
    -- NameOffset ist im PacketDataOut(5)
    -- Die Sensornummer ist in PacketDataOut(4)
    DNMemAddr(11 downto 6)<=PacketDataOut(4)(5 downto 0);
    --DNMemAddr(5 downto 0)<=std_logic_vector(to_unsigned((unsigned(TxState)+unsigned(PacketDataOut(5))),6));
    DNMemAddr(5 downto 0)<= std_logic_vector(
                                to_unsigned(
                                  to_integer(TxState)--Txstate???????
                                   -6
                                   +to_integer(unsigned(PacketDataOut(5)&'0'&'0'&'0')) -- dieses shift multipliziert *8
                                  ,6--??????
                                )
                              );
  end Process;

---------------------------------------------------------------------
--! BT Paket-Empfaenger und -Bearbeitung--????FPGA?????,???????????,???--BT?????
  -- Hier wird jedes eintreffende Paket vom Bluetooth-Adapter verarbeitet--??????????????
  -- inkl. Synchronisation auf Paket-Delimiter(???), Ueberpruefen des CRC
Bluetooth: Process (ClockIn)
  begin
    if rising_edge(ClockIn) then
      if (PacketSent='1') then --???sent,????
        SendPacket<='0';
        SendName<='0';
        PacketDataOut<=(x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
      end if;
            
		if (Reset='1') then    -- Reset von Bluetooth oder ResetButton
        CommandIn<=(others=>'0');
        RxState<=(others=>'0');
        PacketFull<='0';
        SendPacket<='0';
        SetValue<='0';
        GetValue<='0';
        SendName<='0';
        DoCRCIn<='0';
        CRCInReset<='1';
		  
        PWM1FanInsideValueFix<=(others=>'0');		
        PWM2FanOutsideValueFix<=(others=>'0');			
        PWM3LightValueFix<=(others=>'0');					
        PWM4PeltierValueFix<=(others=>'0');			
        PeltierDirectionFix<='0';

		-- Standardwerte fuer Haussteuerung
		InternalHouseOn<='1'; -- high active: default=>an
		ControlLightInt<='0'; -- per default ungeregelt
		ControlTempInt<='0'; -- per default ungeregelt	
		ControlTempTarget<=x"79C"; -- =1948 -> ~20C -- Standardwert der Temperaturregelung
		ControlLightTarget<=x"F48"; --=3912

      else -- ab hier nicht mehr im Reset
		DoCRCIn<='0';
        

---------------------------------------------------------------------
 -- Uart meldet neue Daten
        -- Hier wird jedes Byte einzeln vom Uart entgegen genommen. 
        -- Der RxState wird dabei hochgezaehlt und so je nach Byte des 
        -- 16-Byte Pakets des asha-Protokolls verschiedene Aktionen 
        -- ausgefuehrt.
        --RxState?
        --0,1?????,?????175?5??????
        --2??command??????
        --3??command??
        --4-13?????
        --14,15??CRC???
        if (RxFin='1') then --??uart????
         case RxState is
           when "0000" => -- x"0" StartDelimiter0
             PacketFull<='0'; -- Wenn RxFin=1 und SendPacket=1, dann geht--????Packet??,?????
                              -- ein empfangenes Paket verloren.
                              -- (er faengt ein ein neues Paket zu empfangen, 
                              -- bevor das alte fertig gesendet wurde)
             if (RxData="10101111") then--175
               RxState<=RxState+1;
             end if;
             CRCInReset<='1';
           when "0001" => -- x"1" StartDelimiter1
             if (RxData="00000101") then--5
               RxState<=RxState+1;
             else 
               RxState<=(others=>'0');
             end if;
             CRCInReset<='0';
           when "0010" => -- x"2" ProtokollVersion
             DoCRCIn<='1';
             if (RxData(7 downto 1)="0000000") then
               if not (RxData(7 downto 1)="0000000") then--?
                 RxState<="0000"; --Protokollversion weder 0 noch 1
                 -- => Dieses Paket ignorieren 
                 --    und auf naechsten Delimiter warten
               else
                 RxState<=RxState+1;
                 CommandIn(8)<=RxData(0); -- Protokollversion 0 und 1 
               end if;
             else
               RxState<=(others=>'0');
             end if;
           when "0011" => -- x"3" Command
             DoCRCIn<='1';
             RxState<=RxState+1;
             CommandIn(7 downto 0)<=RxData;

           when "1110" => -- x"E" CRC1
             CRCValueReceived(7 downto 0)<=RxData;
             RxState<=RxState+1;
           when "1111" => -- x"F" CRC2
             CRCValueReceived(15 downto 8)<=RxData;
             RxState<="0000";
             PacketFull<='1'; -- Paket fertig empfangen

             GetValue<='0'; -- spaetestens wenn das naechste paket eintrifft sollte der wert des vorigen vorhanden sein.
             SendPacket<='0'; -- und das Paket soll dann auch nicht versendet werden.


           -- Dies ist eine Zustandsmaschine mit 16 Zustaenden, bei der aber
           -- nur 6 der 16 Zustaende explizit deklariert sind. 
           -- Der folgende others-Zustand springt fuer die restlichen 10 ein,
           -- bei denen nichts weiter passiert als ein Byte zu empfangen,
           -- dieses abzuspeichern, der CRC-Berechnung zuzufueheren und dann
           -- in den naechsten Zustand zu wechseln.
           when others => -- Werte zwischen x"4" und x"D"--4-13?????,????????????
             DoCRCIn<='1';
             PacketDataIn(to_integer(RxState))<=RxData;
             RxState<=RxState+1;

         end case;
        end if;
      end if;

---------------------------------------------------------------------
-- Paket empfangen--??????Paket?????
      -- Dieser Teil wird abgearbeitet, sobald ein neues Paket fertig
      -- eingetroffen ist. Dabei muss darauf geachtet werden, mit der
      -- Bearbeitung erst anzufangen, wenn kein Paket mehr gesendet wird, 
      -- da hier der Ausgangspuffer mit Hilfe des Eingangspuffers belegt wird.
      if (PacketFull='1') and (SendPacket='0') then 
        -- Abfrage auf SendPacket: waehrend gesendet wird, darf nichts 
        -- an den Ausgangspuffern geaendert werden.
        PacketFull<='0';
        if (CRCIn=CRCValueReceived) then -- CRC Korrekt, Sendung vorbereiten
          case CommandIn is
            -- when '0' & x"01" => -- Ping
            when "000000001" =>  -- Ping--1
              CommandOut<="010000001";
              PacketDataOut(4 to 11)<=PacketDataIn(4 to 11);
              PacketDataOut(12)<=(others=>'0');
              PacketDataOut(13)<=(others=>'0');
              SendPacket<='1';
            when "000000010" => -- GetProtocols--2
              commandOut<='0' & x"82";--??:???????0 1000 0010
              PacketDataOut(4)<= x"03";
              SendPacket<='1';
            when "100000001" => -- GetDeviceCount--257
              commandOut<='1' & x"81";--1 1000 0001
              PacketDataOut(4)<= x"1A"; -- 26  Devices 
               -- Auf dem digilent-Board:--??
               -- 5 Sensoren: 4x Taster plus 8 Schalter als ein Byte
               -- 2 Aktoren: 8 LEDs als ein Byte, 1x 4er 7-Segment
               -- extern:--??
               -- 8x analoger Sensor (ADC) (..., 2x spare)--
               -- 1x binaerer Sensor (SensorDoor)--???(?0?1)
               -- 4x PWM Aktor
               -- 2x binaerer Aktor (Peltier Richtung, Haus an/aus)
               -- 2 Regler: Temperatur und Licht
			   -- 2x Sollwert: Temperatur und Licht
              SendPacket<='1';
            when "100000010" => -- GetDeviceInfo--258
              commandOut<='1' & x"82";
              PacketDataOut(4)<=PacketDataIn(4); -- DeviceNumber
              
              -- Die DeviceInfo kann hier schon aus dem Speicher geholt
              -- werden, da die Speicheradresse permanent aus dem Eingangspuffer
              -- angelegt wird und daher schon mindestens einen Takt anliegt.
              PacketDataOut( 5)<=DIMemData(71 downto 64);
              PacketDataOut( 6)<=DIMemData(63 downto 56);
              PacketDataOut( 7)<=DIMemData(55 downto 48);
              PacketDataOut( 8)<=DIMemData(47 downto 40);
              PacketDataOut( 9)<=DIMemData(39 downto 32);
              PacketDataOut(10)<=DIMemData(31 downto 24);
              PacketDataOut(11)<=DIMemData(23 downto 16);
              PacketDataOut(12)<=DIMemData(15 downto 8);
              PacketDataOut(13)<=DIMemData(7 downto 0);
              SendPacket<='1';
            when "100000011" => -- GetDeviceName--259
              commandOut<='1' & x"83";--1 0101 0011
              -- koennen von Eingang uebernommen werden:
              PacketDataOut(4)<=PacketDataIn(4); -- DeviceNumber
              PacketDataOut(5)<=PacketDataIn(5); -- NameOffset
              -- der Rest wird in der Senderoutine ueber den Speicher, an dem schon
              -- durch einen extra vhdl-process die passende Adresse anliegt, gesendet.
              SendName<='1'; -- dies wird dem BT-Sender hierueber signalisiert
              SendPacket<='1';
            when "100000100" => -- GetDeviceValue--260
              commandOut<='1' & x"84";--1 01010100
              PacketDataOut(4)<=PacketDataIn(4); -- DeviceNumber
              -- Die Adresse am ADCRegisterIndex hier schon mal anlegen, damit
              -- sie im naechsten Schritt schon mindestens einen Takt anliegt.
              ADCRegisterIndex<=to_integer(unsigned(DIMemData(74 downto 72))); -- noetige ADC-Adresse liegt hier an, sonst nicht unbedingt, daher Zuweisung hier
              GetValue<='1'; -- der Sensorverarbeitung signalisieren, dass wir einen Wert versenden wollen
              SendPacket<='1';
            when "100000101" => -- SetDeviceValue
              commandOut<='1' & x"85";
              PacketDataOut(4)<=PacketDataIn(4); -- DeviceNumber
              PacketDataOut(5)<=PacketDataIn(5); -- CurrentValueLow
              PacketDataOut(6)<=PacketDataIn(6); -- CurrentValueHigh
              SetValue<='1';
              SendPacket<='1';

            when others =>
              -- alle anderen moeglichen Kombinationen von ProtokollVersion und Command
              -- sind uns unbekannt und werden ignoriert.

          end case;
        else -- CRC kaputt
          -- wenn der CRC kaputt ist, dann wird das Paket schlicht ignoriert.
        end if;
      elsif (PacketFull='1') and (SendPacket='1') then
        -- Paket soll gesendet werden, aber es ist noch eins im Sendevorgang
      end if;

---------------------------------------------------------------------
-- Sensorverarbeitung--???????????fpga??,?????
      -- Dieser Bereich wird abgearbeitet, wenn es laut asha-Protokoll
      -- ein GetDeviceValue ist--?sensor?????????
      if (GetValue='1') then--????????(??button,switch,led??)
        case PacketDataOut(4) is -- (4=DeviceNumber)
          when x"00" => 
            PacketDataOut(5)<=b"00"&LEDs; -- 8 LEDs--??????,?????zybo??????6?
            GetValue<='0';
          when x"01" =>
            PacketDataOut(5)(0)<=Buttons(0); -- Taste 1
            GetValue<='0';
          when x"02" => 
            PacketDataOut(5)(0)<=Buttons(1); -- Taste 2
            GetValue<='0';
          when x"03" =>
            PacketDataOut(5)(0)<=Buttons(2); -- Taste 3
            GetValue<='0';
          when x"04" =>
            PacketDataOut(5)(0)<=Buttons(3); -- Taste 4  -- ist noch Reset
            GetValue<='0';
          when x"05" =>
            PacketDataOut(5)<=b"0000"&Switches; -- 8 Schalter--??,zybo?????Schalter
            GetValue<='0';
          when x"06" =>               -- 7-Segment-Anzeige
            PacketDataOut(5)<=SevenSegmentValue(7 downto 0); --  Low-Byte
            PacketDataOut(6)<=SevenSegmentValue(15 downto 8); -- High-Byte
            GetValue<='0';
          when x"07" | x"08" | x"09" | x"0a" | x"0b" | x"0c" | x"0d" | x"0e"  =>   -- ADC 1-8
            PacketDataOut(5)<=ADCRegister(ADCRegisterIndex)(7 downto 0);
            PacketDataOut(6)<="0000" & ADCRegister(ADCRegisterIndex)(11 downto 8);
            GetValue<='0';
          when x"0f" => -- SensorDoor
            PacketDataOut(5)(0)<=SensorDoor;
            GetValue<='0';
          when x"10" => -- PWM Luefter
            PacketDataOut(5)<=PWM1FanInsideValue;
            GetValue<='0';
          when x"11" => -- PWM Luefter
            PacketDataOut(5)<=PWM2FanOutsideValue;
            GetValue<='0';
          when x"12" => -- PWM Licht
            PacketDataOut(5)<=PWM3LightValue;
            GetValue<='0';
          when x"13" => -- PWM Peltier
            PacketDataOut(5)<=PWM4PeltierValue;
            GetValue<='0';
          when x"14" => -- Peltier Richtung
            PacketDataOut(5)(7 downto 1) <= (others=>'0'); -- TODO: Nullen unnoetig, da vorinitialisiert
            PacketDataOut(5)(0)<= PeltierDirection;
            GetValue<='0';
          when x"15" => -- Haus an/aus
            PacketDataOut(5)(7 downto 1) <= (others=>'0'); -- TODO: Nullen unnoetig, da vorinitialisiert
            PacketDataOut(5)(0)<=InternalHouseOn;
            GetValue<='0';
          when x"16" => -- Reglerdifferenz Temperatur
            PacketDataOut(6) <= "000" & std_logic_vector(ControlTempDiff(12 downto 8));
            PacketDataOut(5) <= std_logic_vector(ControlTempDiff(7 downto 0));
            GetValue<='0';
          when x"17" => -- Reglerdifferenz Licht
            PacketDataOut(6) <= "000" & std_logic_vector(ControlLightDiff(12 downto 8));
            PacketDataOut(5) <= std_logic_vector(ControlLightDiff(7 downto 0));
            GetValue<='0';
          when x"18" => -- Sollwert Temperatur
            PacketDataOut(6) <= "0000" & std_logic_vector(ControlTempTarget(11 downto 8));
            PacketDataOut(5) <= std_logic_vector(ControlTempTarget(7 downto 0));
            GetValue<='0';
          when x"19" => -- Sollwert Licht
            PacketDataOut(6) <= "0000" & std_logic_vector(ControlLightTarget(11 downto 8));
            PacketDataOut(5) <= std_logic_vector(ControlLightTarget(7 downto 0));
            GetValue<='0';
            
          when others =>
            PacketDataOut(5) <= (others=>'1'); -- FF bei unbekannten Sensoren... darf nicht vorkommen.
            PacketDataOut(6) <= (others=>'1');
            GetValue<='0';
        end case;
      end if;
		---------------------------------------------------------------------
-- Aktorverarbeitung
      -- Dieser Bereich wird abgearbeitet, wenn es laut asha-Protokoll
      -- ein SetValue ist
	  -- Versuch 10
      -- TODO: if ...
      -- PacketDataIn
        if (SetValue='1') then--????????(?????PWM?led?sevensegment)
            case PacketDataIn(4) is     
                when x"00" => -- 
                    LEDs <= PacketDataIn(5)(5 downto 0); -- 8 LEDs
                    SetValue<='0';
                when x"06" =>               -- 7-Segment-Anzeige
                    SevenSegmentValue(7 downto 0) <= PacketDataIn(5); --  Low-Byte
                    SevenSegmentValue(15 downto 8) <= PacketDataIn(6); -- High-Byte
                    SetValue<='0';
                when x"10" => -- PWM Luefter
                    PWM1FanInsideValueFix <= PacketDataIn(5);
                    SetValue<='0';
                when x"11" => -- PWM Luefter
                    PWM2FanOutsideValueFix <= PacketDataIn(5);
                    SetValue<='0';
                when x"12" => -- PWM Licht
                    PWM3LightValueFix <= PacketDataIn(5);
                    SetValue<='0';
                when x"13" => -- PWM Peltier
                    PWM4PeltierValueFix <= PacketDataIn(5);
                    SetValue<='0';
                when x"14" => -- Peltier Richtung
                    PeltierDirectionFix <= PacketDataIn(5)(0);
                    SetValue<='0';
                when x"18" => -- Sollwert Temperatur
                    ControlTempTarget(7 downto 0) <= unsigned(PacketDataIn(5));
						  ControlTempTarget(11 downto 8) <= unsigned(PacketDataIn(6)(3 downto 0));
                    SetValue<='0';
                when x"19" => -- Sollwert Licht
                    ControlLightTarget(7 downto 0) <= unsigned(PacketDataIn(5));
						  ControlLightTarget(11 downto 8) <= unsigned(PacketDataIn(6)(3 downto 0));
                    SetValue<='0';
                when others =>
                    SetValue<='0';
            end case;
      end if;
		---------------------------------------------------------------------
    
    end if;
    
  end Process; --BT Empfaenger
  
 ---------------------------------------------------------------------
--! BT Sender--BT?????
  -- Leitet Paketdaten aus dem Puffer PacketDataOut Byteweise zum Uart-Modul,
  -- welcher diese seriell zum Bluetooth-Modul ausgibt
  Process (ClockIn)
  begin
    if rising_edge(ClockIn) then
      DoCRCOut<='0';
      DoWrite<='0';
      PacketSent<='0';
      if (Reset='1') then -- Reset
        DoCRCOut<='0';
        CRCOutReset<='0';
      elsif (SendPacket='1') and (Ready2Send='1') -- Bereit zum Senden
                                          -- und stecke nicht in der:
            and (not (GetValue='1'))      -- Sensorverarbeitung      
            and (not (SetValue='1')) then -- Aktorverarbeitung
            -- Die Aktor- und Sensorverarbeitung kann mehre Takte 
            -- benoetigen, so dass hier gewartet werden muss, bis 
            -- die Daten beteit sind 
        case TxState is
          when "0000" => -- StartDelimiter0
            TxData<="10101111"; -- x"AF"
            DoWrite<='1';
            CRCOutReset<='1';
            TxState<=TxState+1;
          when "0001" => -- StartDelimiter1
            TxData<="00000101"; -- x"05"
            DoWrite<='1';
            CRCOutReset<='0';
            TxState<=TxState+1;
            -- Kein DoCRCOut, weil der verdrehte Delimiter vorberechnet
            -- wird. Siehe Kommentar im CRC-Modul.
          when "0010" => -- ProtokollVersion
            TxData(7 downto 1)<=(others=>'0');
            TxData(0)<=CommandOut(8);
            DoWrite<='1';
            DoCRCOut<='1';
            TxState<=TxState+1;
          when "0011" =>
            TxData<=CommandOut(7 downto 0);
            DoWrite<='1';
            DoCRCOut<='1';
            TxState<=TxState+1;

          -- Wie beim BT-Empfaenger werden nicht alle Zustaender dieser
          -- Zustandsmaschine explizit deklariert. Siehe Kommentar dort.

          when "1110" => 
            TxData<=CRCOut(7 downto 0);
            DoWrite<='1';
            TxState<=TxState+1;
          when "1111" => 
            TxData<=CRCOut(15 downto 8);
            DoWrite<='1';
            PacketSent<='1';
            TxState<="0000";

          when others => 
            if SendName='1' 
              -- bei 0100 (4) und 0101 (5) werden DeviceNumber und NameOffset
              -- uebermittelt, welche auch bei ReturnDeviceName ins
              -- PacketDataOut an passender Stelle gesteckt wurden
              and (not (TxState="0100")) --4
              and (not (TxState="0101")) then--5
              TxData<=DNMemData;
            else 
              -- fuer Zustaender (= Positionen im asha-Paket) zwischen 
              -- 4 und 13 werden einfach die Daten im PacketDataOut( gesendet.
              TxData<=PacketDataOut(to_integer(TxState));
            end if;
            DoWrite<='1';
            DoCRCOut<='1';
            TxState<=TxState+1;
        end case;
      end if;
    end if;
  end Process; -- BT Sender
		  
end Behavioral;
