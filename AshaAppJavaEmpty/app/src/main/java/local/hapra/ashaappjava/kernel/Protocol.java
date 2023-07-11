package local.hapra.ashaappjava.kernel;


import java.util.HashMap;

import local.hapra.ashaappjava.R;


/**
 *	Implementiert Uebertragungsprotokol
 */
public class Protocol {
    private final static byte[] data = new byte[16];

    // Definierte Geraetetypen
    public static final class DeviceType{
        public static final byte Sensor = 				(byte)0x01;
        public static final byte Aktor = 				(byte)0x82;
        public static final byte Regelungswert = 		(byte)0x83;
    }

    // Definierte Sensoren
    public static final class DeviceSubType1 {
        public static final byte Helligkeitssensor =	(byte)0x01;
        public static final byte Drucksensor = 			(byte)0x02;
        public static final byte Feuchtigkeitssensor =  (byte)0x03;
        public static final byte ADC = 					(byte)0x04;
        public static final byte Temperatursensor =     (byte)0x05;
        public static final byte Digitalinput = 		(byte)0x06;
    }

    //  Definierte Name fuer Sensoren
    static public final HashMap<Byte, Integer> Sensors = new HashMap<Byte, Integer>() {
        private static final long serialVersionUID = 1L;{
            put (DeviceSubType1.Helligkeitssensor, R.string.brightness_sensor);
            put (DeviceSubType1.Drucksensor, R.string.pressure_sensor);
            put (DeviceSubType1.Feuchtigkeitssensor, R.string.humidity_sensor);
            put (DeviceSubType1.ADC, R.string.adc);
            put (DeviceSubType1.Temperatursensor, R.string.temperature_sensor);
            put (DeviceSubType1.Digitalinput, R.string.digitalinput);
        }};

    // Definierte Aktoren
    public static final class DeviceSubType2 {
        public static final byte DigitalerIO = 			(byte)0x01;
        public static final byte PWM = 					(byte)0x02;
        public static final byte DAC = 					(byte)0x03;
    }

    // Definierte Namen fuer Aktoren
    static public final HashMap<Byte, String> Aktors = new HashMap<Byte, String>() {
        private static final long serialVersionUID = 1L;{
            put (DeviceSubType2.DigitalerIO, "DigitalerIO");
            put (DeviceSubType2.PWM, "PWM");
            put (DeviceSubType2.DAC, "DAC");
        }};

    // Definierte Datentypen
    public static final class DataType {
        public static final byte Volt = 				(byte)0x01;
        public static final byte Ampere = 				(byte)0x02;
        public static final byte Degree = 				(byte)0x03;
        public static final byte Bar = 					(byte)0x04;
        public static final byte Lux = 					(byte)0x05;
        public static final byte Second = 				(byte)0x06;
        public static final byte Percent = 				(byte)0x07;
        public static final byte Number =				(byte)0x08;
        public static final byte Binary =				(byte)0x09;
    }

    // Definierte Namen fuer Datentypen
    static public final HashMap<Byte, Integer> DataTypes = new HashMap<Byte, Integer>() {
        private static final long serialVersionUID = 1L; {
            put (DataType.Volt, R.string.datatyp_volt);
            put (DataType.Ampere, R.string.datatyp_ampere);
            put (DataType.Degree, R.string.datatyp_degree);
            put (DataType.Bar, R.string.datatyp_bar);
            put (DataType.Lux, R.string.datatyp_lux);
            put (DataType.Second, R.string.datatyp_second);
            put (DataType.Percent, R.string.datatyp_percent);
            put (DataType.Number, R.string.datatyp_number);
            put (DataType.Binary, R.string.datatyp_binary);
        }};

    // Weiter folgen verschiedene Bluetooth-packete, die gesendet/ empfangen werden kšnnen

    public static byte[] Ping (){
        data[0] = (byte)0xaf;	//StartDelemiter0
        data[1] = 0x05;			//StartDelemiter1
        data[2] = 0x00;			//ProtokollVersion
        data[3] = 0x01;			//Payload
        data[4] = 0x55;			//Payload
        data[5] = 0x55;			//Payload
        data[6] = 0x55;			//Payload
        data[7] = 0x55;			//Payload
        data[8] = 0x55;			//Payload
        data[9] = 0x55;			//Payload
        data[10] = 0x55;		//Payload
        data[11] = 0x55;		//Payload
        data[12] = 0x00;		//Payload
        data[13] = 0x00;		//Payload

        short crc = CRC16.calc(data);

        data[14] = (byte)(crc & 0xff); 		//ChecksumLow
        data[15] = (byte)(crc >> 8 & 0xff);	//ChecksumHigh

        return data;
    }


    public static byte[] GetProtocols (){
        data[0] = (byte)0xaf;	//StartDelemiter0
        data[1] = 0x05;			//StartDelemiter1
        data[2] = 0x00;			//ProtokollVersion
        data[3] = 0x02;			//Payload
        data[4] = 0x00;			//Payload
        data[5] = 0x00;			//Payload
        data[6] = 0x00;			//Payload
        data[7] = 0x00;			//Payload
        data[8] = 0x00;			//Payload
        data[9] = 0x00;			//Payload
        data[10] = 0x00;		//Payload
        data[11] = 0x00;		//Payload
        data[12] = 0x00;		//Payload
        data[13] = 0x00;		//Payload

        short crc = CRC16.calc(data);

        data[14] = (byte)(crc & 0xff); 		//ChecksumLow
        data[15] = (byte)(crc >> 8 & 0xff);	//ChecksumHigh

        return data;
    }

    public static byte[] GetDeviceInfo(int number){
        data[0] = (byte) 0xaf;	//StartDelemiter0
        data[1] = 0x05;			//StartDelemiter1
        data[2] = 0x01;			//ProtokollVersion
        data[3] = 0x02;			//Payload
        data[4] = (byte)number; //Payload (DeviceNumber)
        data[5] = 0x00;			//Payload
        data[6] = 0x00;			//Payload
        data[7] = 0x00;			//Payload
        data[8] = 0x00;			//Payload
        data[9] = 0x00;			//Payload
        data[10] = 0x00;		//Payload
        data[11] = 0x00;		//Payload
        data[12] = 0x00;		//Payload
        data[13] = 0x00;		//Payload

        short crc = CRC16.calc(data);

        data[14] = (byte)(crc & 0xff); 		//ChecksumLow
        data[15] = (byte)(crc >> 8 & 0xff);	//ChecksumHigh

        return data;
    }

    public static byte[] GetDeviceCount (){
        data[0] = (byte)0xaf;	//StartDelemiter0
        data[1] = 0x05;			//StartDelemiter1
        data[2] = 0x01;			//ProtokollVersion
        data[3] = 0x01;			//Payload
        data[4] = 0x00;			//Payload
        data[5] = 0x00;			//Payload
        data[6] = 0x00;			//Payload
        data[7] = 0x00;			//Payload
        data[8] = 0x00;			//Payload
        data[9] = 0x00;			//Payload
        data[10] = 0x00;		//Payload
        data[11] = 0x00;		//Payload
        data[12] = 0x00;		//Payload
        data[13] = 0x00;		//Payload

        short crc = CRC16.calc(data);

        data[14] = (byte)(crc & 0xff); 		//ChecksumLow
        data[15] = (byte)(crc >> 8 & 0xff);	//ChecksumHigh

        return data;
    }

    public static byte[] GetDeviceValue(int number) {
        data[0] = (byte)0xaf;	//StartDelemiter0
        data[1] = 0x05;			//StartDelemiter1
        data[2] = 0x01;			//ProtokollVersion
        data[3] = 0x04;			//Payload
        data[4] = (byte)number; //Payload
        data[5] = 0x00;			//Payload
        data[6] = 0x00;			//Payload
        data[7] = 0x00;			//Payload
        data[8] = 0x00;			//Payload
        data[9] = 0x00;			//Payload
        data[10] = 0x00;		//Payload
        data[11] = 0x00;		//Payload
        data[12] = 0x00;		//Payload
        data[13] = 0x00;		//Payload

        short crc = CRC16.calc(data);

        data[14] = (byte)(crc & 0xff); 		//ChecksumLow
        data[15] = (byte)(crc >> 8 & 0xff);	//ChecksumHigh

        return data;
    }

    public static byte[] GetDeviceName (int number, int offset) {
        data[0] = (byte)0xaf;	//StartDelemiter0
        data[1] = 0x05;			//StartDelemiter1
        data[2] = 0x01;			//ProtokollVersion
        data[3] = 0x03;			//Payload
        data[4] = (byte)number; //Payload
        data[5] = (byte)offset; //Payload
        data[6] = 0x00;			//Payload
        data[7] = 0x00;			//Payload
        data[8] = 0x00;			//Payload
        data[9] = 0x00;			//Payload
        data[10] = 0x00;		//Payload
        data[11] = 0x00;		//Payload
        data[12] = 0x00;		//Payload
        data[13] = 0x00;		//Payload

        short crc = CRC16.calc(data);

        data[14] = (byte)(crc & 0xff); 		//ChecksumLow
        data[15] = (byte)(crc >> 8 & 0xff);	//ChecksumHigh

        return data;
    }

    public static byte[] SetDeviceValue (int number, int value) {
        data[0] = (byte)0xaf;	//StartDelemiter0
        data[1] = 0x05;			//StartDelemiter1
        data[2] = 0x01;			//ProtokollVersion
        data[3] = 0x05;			//Payload
        data[4] = (byte)number; //Payload
        data[5] = (byte)(value & 0xff); 	 //Payload
        data[6] = (byte)(value >> 8 & 0xff); //Payload
        data[7] = 0x00;			//Payload
        data[8] = 0x00;			//Payload
        data[9] = 0x00;			//Payload
        data[10] = 0x00;		//Payload
        data[11] = 0x00;		//Payload
        data[12] = 0x00;		//Payload
        data[13] = 0x00;		//Payload

        short crc = CRC16.calc(data);

        data[14] = (byte)(crc & 0xff); 		//ChecksumLow
        data[15] = (byte)(crc >> 8 & 0xff);	//ChecksumHigh

        return data;
    }

    /**
     * ueberprueft ob ein Paket nicht der CRC-Pruefung uebersteht
     * @param packet Paket zum Prueffen
     * @return false wenn CRC dem Paketinhalt entspricht
     */
    public static boolean isInvalid(final byte[] packet){
        short crc = CRC16.calc(packet);

        byte high_byte = (byte)(crc & 0xff);
        byte low_byte = (byte)(crc >> 8 & 0xff);

        return (packet[14] != high_byte) || (packet[15] != low_byte);
    }

    public static boolean isPong (final byte[] packet){
        if (isInvalid(packet))
            return false;

        return (packet[2] == (byte) 0x00) && (packet[3] == (byte) 0x81);
    }


    public static boolean isReturnProtocols (final byte[] packet){
        if (isInvalid(packet))
            return false;

        return packet[2] == (byte) 0x00 && packet[3] == (byte) 0x82;
    }

    public static boolean isReturnDeviceCount (final byte[] packet){
        if (isInvalid(packet))
            return false;

        return packet[2] == (byte) 0x01 && packet[3] == (byte) 0x81;
    }

    public static boolean isReturnDeviceInfo (final byte[] packet, int number){
        if (isInvalid(packet))
            return false;

        return packet[2] == (byte) 0x01 && packet[3] == (byte) 0x82 && packet[4] == (byte) number;
    }

    public static boolean isReturnDeviceName (final byte[] packet, int number){
        if (isInvalid(packet))
            return false;

        return packet[2] == (byte) 0x01 && packet[3] == (byte) 0x83 && packet[4] == (byte) number;
    }

    public static boolean isReturnDeviceValue (final byte[] packet, int number){
        if (isInvalid(packet))
            return false;

        return packet[2] == (byte) 0x01 && packet[3] == (byte) 0x84 && packet[4] == (byte) number;
    }


    public static boolean isAckDeviceValue (final byte[] packet, int number) {
        if (isInvalid(packet))
            return false;

        return packet[2] == (byte) 0x01 && packet[3] == (byte) 0x85 && packet[4] == (byte) number;
    }

    /**
     * Konvertiert ein byte buffer in einen Hex-String
     * @param bytes Byte Buffer zum Konvertieren
     * @return Buffer in Hex String
     */
    public static String toHexString (final byte[] bytes) {
        StringBuilder hex = new StringBuilder();
        for (int i = 0; i < bytes.length; i++) {
            if (i > 0)
                hex.append(":");
            hex.append(Integer.toHexString(bytes[i] & 0xFF));
        }
        return hex.toString();
    }
}
