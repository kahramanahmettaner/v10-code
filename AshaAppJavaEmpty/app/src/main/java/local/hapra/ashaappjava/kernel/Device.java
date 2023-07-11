package local.hapra.ashaappjava.kernel;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Repraesentiert einen Sensor/Aktor
 */
public class Device {
    public static final String DEVICE_ID_1 = "00:12:02:29:01:56";
    public static final String DEVICE_ID_3 = "00:12:03:19:75:14";
    public static final String DEVICE_ID_4 = "00:12:04:05:90:31";
    public static final String DEVICE_ID_5 = "00:11:12:01:05:25";
    public static final String DEVICE_ID_6 = "00:12:04:05:91:18";
    public static final String DEVICE_ID_7 = "00:12:04:06:70:29";



    // Speicher fuer ausgelesene Werte
    private final ArrayList<Float> history = new ArrayList<>();

    protected byte type;
    protected byte subType;

    public int number;
    //Sensor/Aktor Daten
    public String name;
    public byte dataType;
    public int bitDepth;
    public int scale;
    public float minValue;
    public float maxValue;
    private float curValue;

    public float disp_min = 0;
    public float disp_max = 0.01f;

    public Device (int number, byte deviceType, byte deviceSubType, byte dataType, int bitDepth, int scale, int minValue,int maxValue) {
        this.number = number;
        this.type = deviceType;
        this.subType = deviceSubType;
        this.name = "";
        this.dataType = dataType;
        this.bitDepth = bitDepth;
        this.scale = scale;


        this.minValue = (float) Math.pow(10, (scale - 128)) * ((float)minValue - 32767);
        this.maxValue = (float) Math.pow(10, (scale - 128)) * ((float)maxValue - 32767);
    }

    /**
     * Gibt aktuellen Wert zurueck
     * @return aktueller Wert
     */
    public float getValue () {
        return curValue;
    }

    /**
     * Setzt aktuellen Wert
     * @param low low-Byte aus dem Byte-Paket
     * @param high high-Byte aus dem Byte-Paket
     */
    public void setValue (byte low, byte high){
        int value = (int)(get(high) << 8) | get(low);

        float range = maxValue - minValue;
        float bitScale = (float) (Math.pow(2, bitDepth) - 1);

        //Wert konvertieren
        curValue = minValue+(value*range/bitScale);
        //Wert runden
        curValue = (float) Math.round(curValue * 100) / 100;

        synchronized (history) {
            if (history.size() == 0) {
                if (curValue == minValue){
                    disp_max = (float)(curValue + 0.05);
                    disp_min = minValue;
                } else if (curValue == maxValue){
                    disp_max = maxValue;
                    disp_min = (float)(curValue - 0.05);
                } else {
                    disp_max = (float)(curValue + 0.03);
                    disp_min = (float)(curValue - 0.02);
                }
            }
        }

        if (disp_min > curValue) {
            disp_min = curValue;
        } else if (disp_max < curValue) {
            disp_max = curValue;
        }

        synchronized (history) {
            history.add(curValue);
        }
    }

    /**
     * Gibt minimum zurueck
     * @return minimum
     */
    public float getMin () {
        return minValue;
    }

    /**
     * Gibt maximum zurueck
     * @return maximum
     */
    public float getMax () {
        return maxValue;
    }

    /**
     * Gibt Range zurŸck
     * @return range
     */
    public float getRange() {
        return maxValue - minValue;
    }

    /**
     * Gibt alle gespeicherte Werte zurueck
     * @return ArrayList<Float> histroy
     */
    public final ArrayList<Float> getHistory () {
        return history;
    }

    /**
     * Gibt Typ vom Sensor/Aktor zurueck
     * @return type
     */
    public byte getType (){
        return type;
    }

    /**
     * Gibt Subtyp vom Sensor/Aktor zurueck
     * @return subtyp
     */
    public byte getSubType (){
        return subType;
    }

    /**
     * Konvertiert ein Byte in ein Integer
     * @param value Byte-Wert
     * @return konverierter Integer-Wert
     */
    private static int get (byte value) {
        return 0x000000FF & ((int)value);
    }

    /**
     * Byte-Paket wird zum Device geparst
     * @param buffer Puffer
     * @return bytepaket
     */
    public static Device parse (final byte[] buffer) {
        int number = buffer[4];
        byte deviceType = buffer[5];
        byte deviceSubType = buffer[6];
        byte dataType = buffer[7];
        int bitDepth = get(buffer[8]);
        int scale = get(buffer[9]);

        int minValue = (int)((get(buffer[11]) << 8) | get(buffer[10]));
        int maxValue = (int)((get(buffer[13]) << 8) | get(buffer[12]));


        //TODO TEST
		/*
        if (number == 0) {
        	deviceType = (byte)0x82;
        	deviceSubType = (byte)0x02;
        }
		*/

        return new Device (number, deviceType, deviceSubType, dataType, bitDepth, scale, minValue, maxValue);
    }


    private static List<String> devicesAll = Arrays.asList(DEVICE_ID_1, DEVICE_ID_3, DEVICE_ID_4, DEVICE_ID_5, DEVICE_ID_6, DEVICE_ID_7);

    public static String devicesMacToName(String mac){
        if(!devicesAll.contains(mac)) return null;

        String out = null;
        switch(mac){
            case DEVICE_ID_1: out = "ID 1"; break;
            //case DEVICE_ID_2: out= "ID 2"; break;
            case DEVICE_ID_3: out = "ID 3"; break;
            case DEVICE_ID_4: out = "ID 4"; break;
            case DEVICE_ID_5: out = "ID 5"; break;
            case DEVICE_ID_6: out = "ID 6"; break;
            case DEVICE_ID_7: out = "ID 7"; break;
        }
        return out;
    }

}