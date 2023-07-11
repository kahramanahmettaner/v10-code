package local.hapra.ashaappjava.ui;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import local.hapra.ashaappjava.R;
import local.hapra.ashaappjava.kernel.Device;
import local.hapra.ashaappjava.kernel.DeviceContainer;
import local.hapra.ashaappjava.kernel.Logger;
import local.hapra.ashaappjava.kernel.Protocol;


/**
 * Sensor Details Oberflächenfragment
 * hinzugefügt von andbra im Feb 2020
 * @author andbra
 */
public class DeviceFragment extends Fragment {
    private int nummer;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_sensor_device, container, false);

        Activity a = getActivity();
        assert a != null;

        Bundle e = a.getIntent().getExtras();
        assert e != null;

        nummer = e.getInt("DeviceNummer", 0);


        Device device = DeviceContainer.get(nummer);
        if (device == null){
            Toast toast = Toast.makeText(a.getApplicationContext(), "Sensor nicht gefunden", Toast.LENGTH_SHORT);
            toast.show();
            a.finish();
        }
        assert device != null;


        TextView v_number =  view.findViewById(R.id.v_number);
        v_number.setText(String.valueOf(nummer));

        TextView deviceType =  view.findViewById(R.id.v_type);
        deviceType.setText(R.string.genActor);

        TextView deviceSubType =  view.findViewById(R.id.v_subtype);
        deviceSubType.setText(Protocol.Aktors.get(device.getSubType()));

        TextView deviceName =  view.findViewById(R.id.v_name);
        deviceName.setText(device.name);

        TextView dataType =  view.findViewById(R.id.v_datatype);
        //noinspection ConstantConditions
        dataType.setText(Protocol.DataTypes.get(device.dataType));

        TextView bitDepth =  view.findViewById(R.id.v_bitdepth);
        bitDepth.setText(Integer.toHexString(device.bitDepth & 0xFF));

        TextView scale =  view.findViewById(R.id.v_scale);
        scale.setText(Integer.toHexString(device.scale & 0xFF));

        TextView minValue =  view.findViewById(R.id.v_min);
        minValue.setText(String.valueOf(device.minValue));

        TextView maxValue =  view.findViewById(R.id.v_max);
        maxValue.setText(String.valueOf(device.maxValue));

        TextView curValue =  view.findViewById(R.id.v_cur);
        curValue.setText(String.valueOf(device.getValue()));

        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        if(getContext() != null){
            getContext().registerReceiver(broadcastReceiver,new IntentFilter("VALUECHANGED"));
        }
    }


    @Override
    public void onPause() {
        super.onPause();
        if(getContext() != null){
            getContext().unregisterReceiver(broadcastReceiver);
        }
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
    }


    private final BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            if (action != null && action.equals("VALUECHANGED")) {

                if (intent.getExtras() != null && intent.getExtras().getInt("DeviceNumber") == nummer) {
                    Logger.add("recieve VALUECHANGED");
                    Device device = DeviceContainer.get(nummer);
                    if((device != null) && (getActivity() != null)) {
                        TextView curValue = getActivity().findViewById(R.id.v_cur);
                        if(curValue != null){
                            curValue.setText(String.valueOf(device.getValue()));
                        }
                    }else{
                        Toast toast = Toast.makeText(context.getApplicationContext(), "Sensor nicht gefunden", Toast.LENGTH_SHORT);
                        toast.show();
                        if(getActivity() != null) getActivity().finish();
                    }

                }
            }
        }
    };


}
