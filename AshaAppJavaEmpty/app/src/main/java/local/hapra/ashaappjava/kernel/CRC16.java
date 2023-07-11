package local.hapra.ashaappjava.kernel;


/**
 * Klasse zum Berechnen von CRC16
 *
 */
public class CRC16 {

    // Abgeleitet von:
    // http://www.sunshine2k.de/articles/coding/crc/understanding_crc.html
    // 4.3 General CRC-8 bitwise implementation
    // 5. Extending to CRC-16

    // Polynom: x^16+x^12+x^5+1 (1 0001 0000 0010 0001)
    // MSB ist immer 1, brauchen es uns also nicht zu merken.
    public static short generator = 0b0001000000100001;

    public static short crc_byte(short crc, byte data){
        // Erzeuge erst ein short mit zwei bytes data + 0000000 (data als MSBs)
        // xor das Ergebnis mit crc
        crc ^= (data&0xFF)<<8;
        for (byte i = 0; i < 8; i++)
        {
            // short ist signed, MSB entscheidet über Vorzeichen: crc < 0 => MSB ist 1
            if (crc < 0)
            {
                // Verschiebe und Teile
                crc = (short)((crc << 1) ^ generator);
            }
            else
            {
                crc <<= 1;
            }
        }
        return crc;
    }

    /**
     * @param packet bytearray Paket dessen crc berechnet wird
     * @return CRC des Pakets
     */
    public static short calc (byte[] packet){
        // Startwert, zum einfachen Nachrechnen auf 0 gesetzt
        short crc = (short)0x0000;

        // StartDelemiter (0,1) muss nicht im CRC behandelt werden,
        // da das Paket ansonsten sowieso nicht erkannt und damit kontrolliert wird
        // Die letzten beiden Bytes (14,15) sind für den CRC selbst reserviert,
        // brauchen für die Berechnung also ebenfalls nicht herangezogen werden.
        for(int i=2; i<14; i++) {
            crc = crc_byte(crc, packet[i]);
        }
        return crc;
    }
}

