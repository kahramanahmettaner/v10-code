package local.hapra.ashaappjava.kernel;

import java.util.Comparator;

/**
 * Comparator Klasse zum Vergleichen von zwei Devices
 * anhand ihres devicetyps
 */
public class DeviceComporator implements Comparator<Device>{
    @Override
    public int compare(Device lhs, Device rhs) {
        int type1 = lhs.type;
        int type2 = rhs.type;

        return Integer.compare(type2, type1);
    }
}