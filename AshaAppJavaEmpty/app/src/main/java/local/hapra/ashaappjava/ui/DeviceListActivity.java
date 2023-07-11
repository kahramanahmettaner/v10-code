package local.hapra.ashaappjava.ui;

import androidx.appcompat.app.AppCompatActivity;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.TextView;

import java.io.IOException;

import local.hapra.ashaappjava.R;
import local.hapra.ashaappjava.kernel.Bluetooth;
import local.hapra.ashaappjava.kernel.Device;
import local.hapra.ashaappjava.kernel.DeviceAdapter;
import local.hapra.ashaappjava.kernel.DeviceContainer;
import local.hapra.ashaappjava.kernel.Logger;
import local.hapra.ashaappjava.kernel.Protocol;

import static local.hapra.ashaappjava.kernel.Protocol.toHexString;

/**
 * Zeigt die aktuellen Werte eines Gerätes an.
 * Sensor Details Oberflächenfragment
 * aktualisiert von andbra im Feb 2020
 */
public class DeviceListActivity extends AppCompatActivity {

    //private ListView listSensor;
    public static ConnectThread connection = null;
    private DeviceAdapter deviceAdapter = null;
    //private ProgressDialog progressDialog = null;
    //private ProgressBar prograssBar = null;
    boolean run = true;

    /**
     *
     *  Updated by andbra on Feb 2020
     *
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_device_list);

        // Device Name
        TextView tvDeviceListName = findViewById(R.id.tvDeviceListName);
        String a1 = "Name: " + Bluetooth.device.getName();
        tvDeviceListName.setText(a1);

        // Device MAC
        TextView tvDeviceListMAC = findViewById(R.id.tvDeviceListMAC);
        String a2 = "MAC: " + Bluetooth.device.getAddress();
        tvDeviceListMAC.setText(a2);

        // Device BTClass
        TextView tvDeviceListBTClass = findViewById(R.id.tvDeviceListBTClass);
        String a3 = "BTClass: " + Bluetooth.device.getBluetoothClass();
        tvDeviceListBTClass.setText(a3);

        // Device Bond State
        TextView tvDeviceListBondState = findViewById(R.id.tvDeviceListBondState);
        String a4 = "BondState: " + Bluetooth.device.getBondState();
        tvDeviceListBondState.setText(a4);


        deviceAdapter = new DeviceAdapter(this, R.layout.listview_sensors_item, DeviceContainer.getAll());

        ListView lvDeviceListSensors = findViewById(R.id.lvDeviceListSensors);

        lvDeviceListSensors.setAdapter(deviceAdapter);

        lvDeviceListSensors.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                Intent in;

                Device device = deviceAdapter.getItem( position );
                if(device == null) return;

                switch (device.getType()){
                        case Protocol.DeviceType.Sensor:
                            in = new Intent(DeviceListActivity.this, SensorFragmentActivity.class);
                            in.putExtra("DeviceNummer", position );
                            startActivity(in);
                            break;
                        case Protocol.DeviceType.Aktor:
                            in = new Intent(DeviceListActivity.this, AktorActivity.class);
                            in.putExtra("DeviceNummer", position );
                            startActivity(in);
                            break;
                }

            }
        });


        //registerReceiver(broadcastReceiver,new IntentFilter("VALUECHANGED"));

        connection = new ConnectThread();

        connection.start();
    }


    /**
     *
     * @author  andbra
     */
    @Override
    public void onResume() {
        super.onResume();
        registerReceiver(broadcastReceiver,new IntentFilter("VALUECHANGED"));
    }


    /**
     *
     * @author  andbra
     */
    @Override
    public void onPause() {
        super.onPause();
        unregisterReceiver(broadcastReceiver);
    }



    private final BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            assert action != null;
            if (action.equals("VALUECHANGED")) {
                //Logger.add("recieve VALUECHANGED by: " + deviceNumber);
                deviceAdapter.notifyDataSetChanged();
            }
        }
    };


    private class ConnectThread extends Thread {
        boolean isValid = false;

        public void run() {
            try {
                Bluetooth.connect();
                Logger.add("bluetooth connection successfull");

                byte[] buffer = new byte[16];

                Logger.add("Ping");
                do {
                    Logger.add("send: " + toHexString(Protocol.Ping()));
                    Bluetooth.send(Protocol.Ping());

                    Bluetooth.read(buffer);
                    Logger.add("back: " + toHexString(buffer));

                    isValid = Protocol.isPong(buffer);
                    Logger.add("packet is valid: " + isValid);
                } while (!isValid);

                Logger.add("GetDeviceCount");
                final int deviceCount = Bluetooth.readDeviceCount();

                Logger.add("GetDeviceCount: " + deviceCount);


                /*runOnUiThread(new Runnable() {
                    public void run() {
                        //showDialog(1);
                    }
                });*/

                //progressDialog.setMax(deviceCount);

                for (int d = 0; d < deviceCount; d++) {
                    Logger.add("GetDeviceInfo " + d);
                    do {
                        Bluetooth.send(Protocol.GetDeviceInfo(d));
                        Logger.add("send: " + toHexString(Protocol.GetDeviceInfo(d)));
                        Bluetooth.read(buffer);
                        Logger.add("back: " +  toHexString(buffer));

                        isValid = Protocol.isReturnDeviceInfo(buffer, d);
                        Logger.add("packet is valid: " + isValid);
                    } while (!isValid);


                    //neues gerŠt erzeugen
                    final Device device = Device.parse(buffer);

                    Logger.add("GetDeviceName: " + d);
                    device.name = Bluetooth.readName(d);

                    //
                    Logger.add("GetDeviceValue: " + d);
                    do {
                        Bluetooth.send(Protocol.GetDeviceValue(d));
                        Logger.add("send: " + toHexString(Protocol.GetDeviceValue(d)));
                        Bluetooth.read(buffer);
                        Logger.add("back: " + toHexString(buffer));

                        isValid = Protocol.isReturnDeviceValue(buffer, d);
                        Logger.add("packet is valid: " + isValid);
                    } while (!isValid);

                    device.setValue(buffer[5], buffer[6]);

                    //neues GerŠt hinzufŸgen
                    runOnUiThread(new Runnable() {
                        public void run() {
                            DeviceContainer.add(device);
                            deviceAdapter.notifyDataSetChanged();
                            ListView lvDeviceListSensors = (ListView)findViewById(R.id.lvDeviceListSensors);
                            lvDeviceListSensors.refreshDrawableState();
                        }
                    });

                    //progressDialog.setProgress(d);
                }

                //progressDialog.dismiss();

                do {
                    for (int d = 0; d < deviceCount; d++) {
                        if (Bluetooth.getValuePacketToSend){
                            // do {
                            Logger.add("FFsend: " + toHexString(Bluetooth.getValuePacket));
                            Bluetooth.send(Bluetooth.getValuePacket);

                            Bluetooth.read(buffer);
                            Logger.add("back: " + toHexString(buffer));

                            //	Logger.add("packet is valid: " + Protocol.isAckDeviceValue(buffer, nummer));
                            // } while (!Protocol.isAckDeviceValue(buffer, nummer));
                            Bluetooth.getValuePacketToSend = false;
                        }


                        Device device = DeviceContainer.get(d);

                        Bluetooth.send(Protocol.GetDeviceValue(d));
                        //Logger.add("send: " + toHexString(Protocol.GetDeviceValue(d)));
                        Bluetooth.read(buffer);
                        //Logger.add("back: " + toHexString(buffer));

                        isValid = Protocol.isReturnDeviceValue(buffer, d);
                        Logger.add("packet is valid: " + isValid);

                        assert device != null;
                        device.setValue(buffer[5], buffer[6]);
                        Intent intent = new Intent("VALUECHANGED");
                        intent.putExtra("DeviceNumber", device.number);

                        sendBroadcast(intent);

                    }
                } while (run);

            } catch (IOException connectException) {
                Logger.add("bt error: " + connectException.getMessage());

                // Unable to connect; close the socket and get out
                try {
                    Bluetooth.disconnect();
                } catch (IOException closeException) {
                    Logger.add("bt error: " + connectException.getMessage());
                }

                return;
            }

            Logger.add("complete");
        }
    }



    @Override
    protected void onDestroy() {
        connection.interrupt();
        try {
            Bluetooth.disconnect();
        } catch (IOException e) {
            Logger.add("<error> " + e);
        }
        deviceAdapter.clear();

        //unregisterReceiver(broadcastReceiver);	//BroadcastReceiver unregistrieren
        super.onDestroy();
    }
}