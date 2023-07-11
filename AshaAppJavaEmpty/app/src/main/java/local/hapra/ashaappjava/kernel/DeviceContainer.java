package local.hapra.ashaappjava.kernel;

import java.util.ArrayList;

/**
 * Kontainer fuer ausgelesene Sensoren/Aktoren
 */
public class DeviceContainer {
    private static ArrayList<Device> devices = new ArrayList<>();

    private DeviceContainer (){}

    /**
     * Fuegt neuen Sensor/Aktor hinzu
     * @param device neuer Sensor/Aktor
     */
    public static void add (Device device){
        devices.add(device);
    }

    /**
     * Gibt alle Sensoren/Aktoren zurŸck
     * @return alle Sensoren/Aktoren
     */
    public static ArrayList<Device> getAll() {
        return devices;
    }

    /**
     * Gibt einen bestimmten Sensor/Aktor zurueck
     * @param index nummer des Sensors/Aktors
     * @return gewŸnschter Sensor/Aktor
     */
    public static Device get (int index){
        if (devices.isEmpty())
            return null;

        return devices.get(index);
    }

    public static int size(){
        return devices.size();
    }
}
