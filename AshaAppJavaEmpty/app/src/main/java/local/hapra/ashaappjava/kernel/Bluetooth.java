package local.hapra.ashaappjava.kernel;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;

import static local.hapra.ashaappjava.kernel.Protocol.toHexString;

/**
 * Bluetooth-Verbindung
 *
 */
public class Bluetooth {
    // Lesebuffer
    private final static byte[] buffer = new byte[16];
    private final static byte[] temp_buffer = new byte[16];

    // entfernter BluetoothDevice (Mikrokontroller oder FPGA)
    public static BluetoothDevice device = null;
    public static BluetoothSocket socket = null;
    public static OutputStream output = null;
    public static InputStream input = null;

    public static boolean getValuePacketToSend = false;
    public static byte[] getValuePacket = new byte[16];
    //private static byte[] packet;

    public static void setBluetoothDevice (BluetoothDevice device) {
        Bluetooth.device = device;

        // Get a BluetoothSocket to connect with the given BluetoothDevice
        try {
            // MY_UUID is the app's UUID string, also used by the server code
            socket = Bluetooth.device.createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805f9b34fb"));
            output = socket.getOutputStream();
            input = socket.getInputStream();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    /**
     * Stellt die Verbindung her
     * @throws IOException IOException from Socket
     */
    public static void connect () throws IOException {
        if (socket != null)
            socket.connect();
    }

    /**
     * Schliesst die Verbindung
     * @throws IOException IOException from Socket
     */
    public static void disconnect () throws IOException {
        if (socket != null)
            socket.close();
    }

    /**
     * Sendet Byte-Paket an entferntes Device
     * @param packet payload
     * @throws IOException IOException from Socket
     */
    public synchronized static void send (final byte[] packet) throws IOException {
        output.write(packet);
        output.flush();
    }

    private static void clearPacket(byte[] packet) {
        for (int i = 0; i < 16; i++){
            packet[i] = 0;
        }
    }

    public synchronized static void read (byte[] packet) throws IOException {
        int read_all = 0;
        int read;

        clearPacket(buffer);
        clearPacket(temp_buffer);

        do {
            read = input.read(temp_buffer, 0, 1);
            //Logger.add(toHexString(temp_buffer));
        } while (temp_buffer[0] != (byte)0xaf);

        do {
            read = input.read(temp_buffer, 1, 1);
            //Logger.add(toHexString(temp_buffer));
        } while (temp_buffer[1] != (byte)0x05);

        System.arraycopy(temp_buffer, 0, packet, 0, 2);
        read = 2;
        do{
            read_all += read;
            read = input.read(temp_buffer);
            //Logger.add(toHexString(temp_buffer));
            if ((read_all + read) > 16) {
                read = 16 - read_all;
            }
            System.arraycopy(temp_buffer, 0, packet, read_all, read);
        }while (read_all + read<16);

        //Logger.add(toHexString(packet));
    }

    public synchronized static String readName (int number) throws IOException{
        StringBuilder name = new StringBuilder();
        boolean isValid;

        int offset = 0;
        do{
            do {
                send(Protocol.GetDeviceName(number, offset));
                Logger.add("send: " + toHexString(Protocol.GetDeviceName(number, 0)));
                Bluetooth.read(buffer);
                Logger.add("back: " + toHexString(buffer));

                isValid = Protocol.isReturnDeviceName(buffer, number);
                Logger.add("packet is valid: " + isValid);
            } while (!isValid);

            name.append(new String(buffer, 6, 8));


            offset+=1;
        }while (buffer[13] != 0);

        return name.toString().trim();
    }

    public synchronized static int readDeviceCount () throws IOException {
        boolean isValid;
        do {
            Logger.add("send: " + toHexString(Protocol.GetDeviceCount()));
            send(Protocol.GetDeviceCount());

            read(buffer);
            Logger.add("back: " + toHexString(buffer));
            isValid = Protocol.isReturnDeviceCount(buffer);

            Logger.add("packet is valid: " + isValid);
        } while (!isValid);

        return buffer[4];
    }
}

