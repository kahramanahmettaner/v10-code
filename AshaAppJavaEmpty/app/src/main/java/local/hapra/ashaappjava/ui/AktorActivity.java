package local.hapra.ashaappjava.ui;

import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.view.View;
import android.view.ViewStub;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import local.hapra.ashaappjava.R;
import local.hapra.ashaappjava.kernel.Bluetooth;
import local.hapra.ashaappjava.kernel.Device;
import local.hapra.ashaappjava.kernel.DeviceContainer;
import local.hapra.ashaappjava.kernel.Logger;
import local.hapra.ashaappjava.kernel.Protocol;

/**
 * Zeigt die Details eines Aktors an. Der AAktor kann gesteuert werden.
 * aktualisiert von andbra im Feb 2020
 */
public class AktorActivity extends AppCompatActivity {
    private TextView curValue;
    private SeekBar sbSetAktor;

    private int nummer;
    private Device device = null;

    private final BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {
        @SuppressLint("SetTextI18n")
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            assert action != null;
            if (action.equals("VALUECHANGED")) {

                if (intent.hasExtra("DeviceNumber") && nummer == intent.getIntExtra("DeviceNumber", 0)) {
                    Logger.add("recieve VALUECHANGED");
                    Device device = DeviceContainer.get(nummer);
                    if (device == null){
                        Toast toast = Toast.makeText(getApplicationContext(), "Sensor nicht gefunden", Toast.LENGTH_SHORT);
                        toast.show();
                    }else{
                        curValue.setText(Float.toString(device.getValue()));
                    }
                }
            }
        }
    };


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_aktor);

        nummer = getIntent().getIntExtra("DeviceNummer", 0);

        device = DeviceContainer.get(nummer);
        if (device == null){
            Toast toast = Toast.makeText(getApplicationContext(), "Sensor nicht gefunden", Toast.LENGTH_SHORT);
            toast.show();
            finish();
        }

        TextView deviceNummer =  findViewById(R.id.v_number);
        deviceNummer.setText(String.valueOf(nummer));

        TextView deviceType =  findViewById(R.id.v_type);
        deviceType.setText(R.string.genActor);

        TextView deviceSubType =  findViewById(R.id.v_subtype);
        deviceSubType.setText(Protocol.Aktors.get(device.getSubType()));

        TextView deviceName =  findViewById(R.id.v_name);
        deviceName.setText(device.name);

        TextView dataType =  findViewById(R.id.v_datatype);
        //noinspection ConstantConditions
        dataType.setText(Protocol.DataTypes.get(device.dataType));

        TextView bitDepth =  findViewById(R.id.v_bitdepth);
        bitDepth.setText(Integer.toHexString(device.bitDepth & 0xFF));

        TextView scale =  findViewById(R.id.v_scale);
        scale.setText(Integer.toHexString(device.scale & 0xFF));

        TextView minValue =  findViewById(R.id.v_min);
        minValue.setText(String.valueOf(device.minValue));

        TextView maxValue =  findViewById(R.id.v_max);
        maxValue.setText(String.valueOf(device.maxValue));

        curValue = findViewById(R.id.v_cur);
        curValue.setText(String.valueOf(device.getValue()));



        ViewStub viewStub = findViewById(R.id.vsAktor);
        //ViewGroup clSetValue = (ViewGroup) findViewById(R.id.clSetValue);

        if (device.bitDepth == 1) {
            viewStub.setLayoutResource(R.layout.aktordialog1);
            viewStub.inflate();

            TextView tvAktorDialog1 =  findViewById(R.id.tvAktorDialog1);

            tvAktorDialog1.setText(String.valueOf(Math.round(device.getValue())));


            CheckBox checkbox = findViewById(R.id.cbAktorDialog1);
            if (device.getValue() != 0){
                checkbox.setChecked(true);
            } else {
                checkbox.setChecked(false);
            }

            checkbox.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
                @Override
                public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                    TextView tvAktorDialog1 =  findViewById(R.id.tvAktorDialog1);
                    if (isChecked) {
                        tvAktorDialog1.setText("1");
                    } else {
                        tvAktorDialog1.setText("0");
                    }
                }
            });

        } else {
            //View.inflate(this, R.layout.aktordialog, clSetValue);
            viewStub.setLayoutResource(R.layout.aktordialog);
            viewStub.inflate();

            sbSetAktor = findViewById(R.id.sbAktorDialog);

            sbSetAktor.setMin(Math.round(device.getMin()));
            sbSetAktor.setMax(Math.round(device.getMax()));
            sbSetAktor.setProgress(Math.round(device.getValue()));

            TextView tvalue =  findViewById(R.id.tvAktorDialog);
            tvalue.setText(String.valueOf((int)(device.getValue())));


            sbSetAktor.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {

                @Override
                public void onStopTrackingTouch(SeekBar seekBar) {
                }

                @Override
                public void onStartTrackingTouch(SeekBar seekBar) {   }

                @Override
                public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {

                    TextView tvalue = findViewById(R.id.tvAktorDialog);
                    tvalue.setText(String.valueOf(progress));

                }
            });
        }


        Button btnAktorSetValue = findViewById(R.id.btnAktorSetValue);

        btnAktorSetValue.setOnClickListener(new Button.OnClickListener() {
            @Override
            public void onClick(View v) {


                AlertDialog.Builder builder = new AlertDialog.Builder(AktorActivity.this);
                builder.setMessage(getResources().getString(R.string.set_value));
                builder.setTitle(getResources().getString(R.string.adTitleSetValue));
                builder.setCancelable(false);

                builder.setPositiveButton(getResources().getString(R.string.set), new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        if (device.bitDepth == 1) {
                            CheckBox checkbox = findViewById(R.id.cbAktorDialog1);

                            if (checkbox.isChecked()) {
                                Bluetooth.getValuePacketToSend = true;
                                Bluetooth.getValuePacket = Protocol.SetDeviceValue(nummer, 1);
                            } else {
                                Bluetooth.getValuePacketToSend = true;
                                Bluetooth.getValuePacket = Protocol.SetDeviceValue(nummer, 0);
                            }

                        }else{

                            sbSetAktor = findViewById(R.id.sbAktorDialog);
                            float range = device.maxValue - device.minValue;
                            float bitScale = (float) (Math.pow(2, device.bitDepth) - 1);
                            int value = sbSetAktor.getProgress();

                            value = (int)((value) * bitScale / range);

                            Bluetooth.getValuePacketToSend = true;
                            Bluetooth.getValuePacket = Protocol.SetDeviceValue(nummer, value);
                        }
                    }
                });

                builder.setNegativeButton(getResources().getString(R.string.cancel), new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        dialog.cancel();
                    }
                });
                builder.show();

            }
        });


        //registerReceiver(broadcastReceiver,new IntentFilter("VALUECHANGED"));
    }


    /**
     *
     * @author  andbra
     */
    @Override
    public void onResume() {
        super.onResume();
        registerReceiver(broadcastReceiver, new IntentFilter("VALUECHANGED"));
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

    @Override
    protected void onDestroy() {
        // TODO Auto-generated method stub
        super.onDestroy();

        //connection.cancel();
        //unregisterReceiver(broadcastReceiver);
    }
}