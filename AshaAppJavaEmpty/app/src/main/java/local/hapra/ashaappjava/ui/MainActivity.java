package local.hapra.ashaappjava.ui;




import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.SimpleAdapter;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import local.hapra.ashaappjava.R;
import local.hapra.ashaappjava.kernel.Bluetooth;
import local.hapra.ashaappjava.kernel.Device;
import local.hapra.ashaappjava.kernel.Logger;
import local.hapra.ashaappjava.kernel.Utils;


/**
 * Hauptactivity
 * Diese Activity dient dazu, andere Bluetooth-Geräte zu finden und diese aufzulisten. Bei Auswahl eines Gerätes
 * wird eine neue Activity gestartet.
 * aktualisiert von andbra im Feb 2020
 */
public class MainActivity extends AppCompatActivity {
    // Intent Request Code für Bluetooth
    private static final int REQUEST_ENABLE_BT = 1;
    private static final int REQUEST_ENABLE_GPS = 2;
    private static final int REQUEST_CONNECT_DEVICE_SECURE = 1;

    // Liste mit allen gefundenen Bluetooth-Geräten
    private ArrayList<BluetoothDevice> devicesObjList = new ArrayList<>();
    // Liste mit allen gefundenen Bluetooth-Geräten
    private ArrayList<String> devicesAddressList = new ArrayList<>();
    // Liste mit Namen und MACs
    private List<Map<String, String>> devicesNameList = new ArrayList<>();
    // Adapter für die ListView
    private SimpleAdapter devicesListAdapter = null;

    /**
     * Initialisierung der Activity
     * Prüfen, ob ein BT Adapter vorhanden ist
     * Listener zuweisen
     *
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // setzt das aktuelle Layout
        setContentView(R.layout.activity_main);

        // Bluetooth Adapter laden
        final BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter ();

        // lädt die Switch-Objekte, um in dieser Funktion zu verwenden
        Switch swFilterDevices = findViewById(R.id.swFilterDevices);
        //Button zum Starten der Bluetooth-Geräte Suche
        Button btnRefresh = findViewById(R.id.btnRefresh);

        // Prüfen, ob das Gerät Bluetooth besitzt.
        if ( mBluetoothAdapter == null ) {
            Toast.makeText (this, R.string.errNoBluetooth, Toast.LENGTH_LONG ).show () ;
            TextView tvClickToConnectLabel = findViewById(R.id.tvClickToConnectLabel);
            tvClickToConnectLabel.setText(R.string.errNoBluetooth);
            btnRefresh.setEnabled(false);
            swFilterDevices.setEnabled(false);
            return;
        }

        // Adapter für ListVIew initialisieren
        devicesListAdapter = new SimpleAdapter(this, devicesNameList, R.layout.listview_devices_item,
                new String[] {"name", "mac"},
                new int[] {R.id.tvListViewName, R.id.tvListViewMac});

        ListView listDevices = findViewById(R.id.lvMainDevices);

        listDevices.setAdapter(devicesListAdapter);

        // Klick-Listener für die Verbindung zu dem Gerät
        listDevices.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            //Bei Klick auf ein Bluetooth-Gerät weitere Suche abbrechen und Bluetooth-Gerät über die
            //id setzen. Neuen Intent erstellen und neue Activity starten.
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                // TODO-3
                // Bluetooth suche beenden
                // Bluetooth Device in Klasse Bluetooth setzen
                // zur Activity DeviceListActivity wechseln, sichere Device Verbindung anfordern
                // Hinweis: startActivityForResult (intent, REQUEST_CONNECT_DEVICE_SECURE ) ;

                if (mBluetoothAdapter.isDiscovering()) {
                    mBluetoothAdapter.cancelDiscovery();
                }

                Bluetooth.setBluetoothDevice(devicesObjList.get(position));

                Intent intent = new Intent(MainActivity.this, DeviceListActivity.class);
                startActivityForResult(intent, REQUEST_CONNECT_DEVICE_SECURE);

            }
        });


        btnRefresh.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {

                // gefundenen Geräte zurücksetzen
                devicesNameList.clear();
                devicesAddressList.clear();
                devicesObjList.clear();
                devicesListAdapter.notifyDataSetChanged();

                // TODO 1 MainActivity.onCreate()
                // Berechtigung prüfen
                boolean permission_ACCESS_FINE_LOCATION = ActivityCompat.checkSelfPermission(
                        MainActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) ==
                        PackageManager.PERMISSION_GRANTED;
                Log.d("BT_PERMISSION", "ACCESS_FINE_LOCATION: " + Boolean.toString(permission_ACCESS_FINE_LOCATION));

                boolean permission_BLUETOOTH = ActivityCompat.checkSelfPermission(
                        MainActivity.this, Manifest.permission.BLUETOOTH) ==
                        PackageManager.PERMISSION_GRANTED;
                Log.d("BT_PERMISSION", "BLUETOOTH: " + Boolean.toString(permission_BLUETOOTH));

                boolean permission_BLUETOOTH_ADMIN = ActivityCompat.checkSelfPermission(
                        MainActivity.this, Manifest.permission.BLUETOOTH_ADMIN) ==
                        PackageManager.PERMISSION_GRANTED;
                Log.d("BT_PERMISSION", "BLUETOOTH_ADMIN: " + Boolean.toString(permission_BLUETOOTH_ADMIN));

                // Berechtigung anfragen
                if (!permission_ACCESS_FINE_LOCATION) {
                    requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, REQUEST_ENABLE_GPS);
                }
                if (!permission_ACCESS_FINE_LOCATION) {
                    requestPermissions(new String[]{Manifest.permission.BLUETOOTH}, REQUEST_ENABLE_BT);
                }
                if (!permission_ACCESS_FINE_LOCATION) {
                    requestPermissions(new String[]{Manifest.permission.BLUETOOTH_ADMIN}, REQUEST_CONNECT_DEVICE_SECURE);
                }

                Toast.makeText(MainActivity.this, Boolean.toString(mBluetoothAdapter.isDiscovering()), Toast.LENGTH_SHORT).show();
                // Bluetooth Status prüfen und ggf. Aktivierung anfordern (ACTION_REQUEST_ENABLE), startActivityForResult
                if (!mBluetoothAdapter.isEnabled()) {
                    Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                    startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
                } else {
                    // Bluetooth Suche starten
                    if (mBluetoothAdapter.isDiscovering()) {
                        mBluetoothAdapter.cancelDiscovery();
                    }
                    mBluetoothAdapter.startDiscovery();
                }

            }
        });
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();

        // Broadcast Reciever abmelden
        unregisterReceiver(broadcastReceiver);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        switch (requestCode) {

            case REQUEST_ENABLE_BT:
                if ( resultCode == Activity.RESULT_OK ) {
                    Toast.makeText(this, "BT ENABLED", Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(this, R.string.bt_not_enabled_leaving, Toast.LENGTH_SHORT).show();
                }
                break;
            /*case REQUEST_CONNECT_DEVICE_SECURE:
                break;
            */
        }
    }


    /**
     * Behandelt das Ergebnis der Berechtigungsanfrage
     */
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        // wenn der Wert der Variable requestCode mit der Anfrage übereinstimmt
        if (requestCode == REQUEST_ENABLE_GPS) {
            if (grantResults.length > 0 && grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, R.string.errPermissionDenied, Toast.LENGTH_LONG).show();
            }
        }
    }

    /**
     *
     * @author  andbra
     */
    @Override
    public void onResume() {
        super.onResume();
        // TODO 2 MainActivity.onResume()
        // BroadcastReceiver registrieren. (Muss in onDestroy deregistriert werden!!)
        IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
        registerReceiver(broadcastReceiver, filter);

        filter = new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        registerReceiver(broadcastReceiver, filter);

        filter = new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
        registerReceiver(broadcastReceiver, filter);
    }



    @Override
    protected void onPause() {
        super.onPause();
        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter ();
        if ( mBluetoothAdapter != null  && mBluetoothAdapter.isDiscovering () ) {
            mBluetoothAdapter.cancelDiscovery () ;
        }
        unregisterReceiver(broadcastReceiver);	//BroadcastReceiver deregistrieren

        devicesNameList.clear();
        devicesAddressList.clear();
        devicesObjList.clear();
        devicesListAdapter.notifyDataSetChanged();
    }


    /**
     * Menü
     * @return true
     */
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.preferences_menu, menu);
        return true;
    }

    /**
     * BroadcastReceiver zum Empfang von Broadcast Nachrichten.
     */
    private final BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {
        //
        /**
         * Behandlung der Nachrichten ACTION_FOUND, ACTION_DISCOVERY_STARTED,
         * ACTION_DISCOVERY_FINISHED
         */
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            // neues Gerät wurde gefunden
            Toast.makeText(MainActivity.this, "ONRECEIVE", Toast.LENGTH_SHORT).show();
            assert action != null;
            switch (action) {
                case BluetoothDevice.ACTION_FOUND: {
                    // BluetoothDevice Objekt von Intent holen
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    Switch swFilterDevices = findViewById(R.id.swFilterDevices);

                    if(device == null) {
                        Logger.add("null device");
                        break;
                    }

                    // @andbra
                    // Gerät bereits aufgelistet
                    if(devicesObjList.contains(device) || devicesAddressList.contains(device.getAddress())){
                        break;
                    }


                    String id = Device.devicesMacToName(device.getAddress());
                    if(swFilterDevices.isChecked() && id == null){
                        Logger.add("found: " + device.getName() + " " + device.getAddress() + " sort out");
                        break;
                    }

                    // Name und Adresse zu ListView hinzufügen
                    Map<String, String> datum = new HashMap<>(2);

                    if(id != null){
                        datum.put("name", device.getName() + " (ASHA "+ id + ")");
                    }else{
                        datum.put("name", device.getName());
                    }
                    datum.put("mac", device.getAddress());
                    devicesNameList.add(datum);
                    devicesObjList.add(device);
                    devicesAddressList.add(device.getAddress());

                    // Adapter aktualisieren, da ein neues Gerät hinzugekommen ist
                    devicesListAdapter.notifyDataSetChanged();
                    Logger.add("found: " + device.getName() + " " + device.getAddress());
                    // Ausgabe einer kurzen Meldung, dass ein Gerät gefunden wurde
                    //Toast toast = Toast.makeText(getApplicationContext(), getResources().getString(R.string.find_new_device) + device.getName(), Toast.LENGTH_SHORT);
                    //toast.show();

                    // Suche wurde gestartet
                    break;
                }
                case BluetoothAdapter.ACTION_DISCOVERY_STARTED: {
                    //Logger.add("start discovery");
                    // ProgressBar anzeigen
                    ProgressBar pgSearching = findViewById(R.id.pgSearching);
                    pgSearching.setVisibility(View.VISIBLE);
                    // Button deaktivieren
                    Button sw = findViewById(R.id.btnRefresh);
                    sw.setEnabled(false);
                    // Ausgabe einer kurzen Meldung, dass die Gerätesuche gestartet wurde
                    Toast toast = Toast.makeText(getApplicationContext(), getResources().getString(R.string.search_started), Toast.LENGTH_SHORT);
                    toast.show();

                    // Suche wurde beendet
                    break;
                }
                case BluetoothAdapter.ACTION_DISCOVERY_FINISHED: {
                    //Logger.add("stop discovery");
                    //ProgressBar verstecken
                    ProgressBar pgSearching = findViewById(R.id.pgSearching);
                    pgSearching.setVisibility(View.GONE);
                    // Button aktivieren
                    Button sw = findViewById(R.id.btnRefresh);
                    sw.setEnabled(true);
                    // Ausgabe einer kurzen Meldung, dass die Gerätesuche beendet wurde
                    Toast toast = Toast.makeText(getApplicationContext(), "Suche nach Geräten beendet !", Toast.LENGTH_SHORT);
                    toast.show();
                    break;
                }
            }
        }
    };


    /**
     * Für Menu: Logger sowie Sprachwahl deutsch/englisch einrichten
     */
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        Intent in;
        switch (item.getItemId()) {
            case R.id.itmExit:
                doExit();  // beendet die App
                return true;
            case R.id.itmLogger:
                // starte logger Activity
                in = new Intent(MainActivity.this, LoggerActivity.class);
                startActivity(in);
                return true;
            case R.id.language_english:
                // Sprache auf Englisch setzen
                Utils.setCurrentLocale("en");
                // aktuallisiere Activity
                refreshActivity();
                Logger.add("set language: english");
                return true;
            case R.id.language_german:
                // Sprache auf Deutsch setzen
                Utils.setCurrentLocale("de");
                // aktuallisiere Activity
                refreshActivity();
                Logger.add("set language: german");
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    /**
     * Ändern den Context in die gewünschte Sprache
     * hinzugefügt iim Feb2020 von andbra
     */
    @Override
    protected void attachBaseContext(Context oldContext) {
        Context context = Utils.changeLang(oldContext);
        super.attachBaseContext(context);
    }

    /**
     * Activity aktualisieren
     */
    protected void refreshActivity () {
        //Activity beenden
        finish();
        //Neue Activity erzeugen
        Intent myIntent = new Intent(MainActivity.this, MainActivity.class);
        startActivity(myIntent);
    }

    /**
     * Beendet die App
     * @author  andbra
     */
    private void doExit(){
        new AlertDialog.Builder(this)
                .setTitle(R.string.exitConfirmTitle)
                .setMessage(R.string.exitConfirmText)
                .setPositiveButton(R.string.btnOkText,
                        new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog,int which) {
                                finishAffinity(); // beendet die App
                            }})
                .setNegativeButton(R.string.btnCancelText,
                        new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog,int which) {
                                // keine Aktion
                            }})
                .show();
    }


}


