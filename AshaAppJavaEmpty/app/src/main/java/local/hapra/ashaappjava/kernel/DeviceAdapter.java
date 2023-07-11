package local.hapra.ashaappjava.kernel;


import java.util.List;

import local.hapra.ashaappjava.R;


import androidx.annotation.NonNull;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import static local.hapra.ashaappjava.kernel.Protocol.Sensors;

public class DeviceAdapter extends ArrayAdapter<Device> {
    private Context context;
    private int layoutResourceId;
    private List<Device> data;

    public DeviceAdapter(Context context, int layoutResourceId, List<Device> data) {
        super(context, layoutResourceId, data);

        this.layoutResourceId = layoutResourceId;
        this.context = context;
        this.data = data;
    }



    @NonNull
    @Override
    @SuppressLint("SetTextI18n")
    public View getView(int position, View convertView, ViewGroup parent) {
        View row = convertView;
        DeviceHolder holder;

        if(row == null) {
            LayoutInflater inflater = ((Activity)context).getLayoutInflater();
            row = inflater.inflate(layoutResourceId, parent, false);

            holder = new DeviceHolder();
            holder.type = row.findViewById(R.id.tvSensorTyp);
            holder.subType = row.findViewById(R.id.tvSubTyp);
            holder.name = row.findViewById(R.id.tvName);
            holder.min = row.findViewById(R.id.tvMinValue);
            holder.max = row.findViewById(R.id.tvMaxValue);
            holder.curValue = row.findViewById(R.id.tvCurValue);
            holder.dataType = row.findViewById(R.id.tvDataType);

            row.setTag(holder);
        } else {
            holder = (DeviceHolder) row.getTag();
        }

        Device device = data.get(position);

        switch (device.getType()){
            case Protocol.DeviceType.Sensor:
                holder.type.setText(R.string.genSensor);

                if (Sensors.containsKey(device.getSubType())){
                    //noinspection ConstantConditions
                    holder.subType.setText(Sensors.get(device.getSubType()));
                } else {
                    holder.subType.setText("undef: " + device.getSubType());
                }

        	/*
            switch (device.getSubType()) {
    		case Protocol.DeviceSubType1.Helligkeitssensor:
    			holder.subType.setText("Helligkeitssensor");
    			break;
    		case Protocol.DeviceSubType1.Drucksensor:
    			holder.subType.setText("Drucksensor");
    			break;
    		case Protocol.DeviceSubType1.Feuchtigkeitssensor:
    			holder.subType.setText("Feuchtigkeitsensor");
    			break;
    		case Protocol.DeviceSubType1.ADC:
    			holder.subType.setText("ADC");
    			break;
    		case Protocol.DeviceSubType1.Temperatursensor:
    			holder.subType.setText("Temperatursensor");
    			break;
    		case Protocol.DeviceSubType1.Digitalinput:
    			holder.subType.setText("Digitalinput");
    			break;
    		default:
    			holder.subType.setText("undefined: " + device.getSubType());
    			break;
    		}
        	*/
                break;
            case Protocol.DeviceType.Aktor:
                holder.type.setText(R.string.genActor);

                if (Protocol.Aktors.containsKey(device.getSubType())){
                    holder.subType.setText(Protocol.Aktors.get(device.getSubType()));
                } else {
                    holder.subType.setText("undef: " + device.getSubType());
                }

        	/*
            switch (device.getSubType()) {
    		case Protocol.DeviceSubType2.DigitalerIO:
    			holder.subType.setText("DigitalerIO");
    			break;
    		case Protocol.DeviceSubType2.PWM:
    			holder.subType.setText("PWM");
    			break;
    		case Protocol.DeviceSubType2.DAC:
    			holder.subType.setText("DAC");
    			break;
    		default:
    			holder.subType.setText("undefined: " + device.getSubType());
    			break;
    		}
        	*/
                break;
            case Protocol.DeviceType.Regelungswert:
                holder.type.setText(R.string.genControlValue);
                break;
            default:
                holder.type.setText("<undefined> " + device.getType());
                break;
        }


        holder.name.setText("Name: " + device.name);
        holder.min.setText("MinValue: " + device.minValue);
        holder.max.setText("MaxValue: " + device.maxValue);
        holder.curValue.setText(String.valueOf(device.getValue()));

        if (Protocol.DataTypes.containsKey(device.dataType)){
            //noinspection ConstantConditions
            holder.dataType.setText(Protocol.DataTypes.get(device.dataType));
        } else {
            holder.dataType.setText("undef: " + device.dataType);
        }


        /*
        switch (device.dataType) {
        case Protocol.DataType.Volt:
            holder.dataType.setText("Volt");
        	break;
        case Protocol.DataType.Ampere:
            holder.dataType.setText("Ampere");
        	break;
        case Protocol.DataType.Degree:
            holder.dataType.setText("Degree");
        	break;
        case Protocol.DataType.Bar:
            holder.dataType.setText("Bar");
        	break;
        case Protocol.DataType.Lux:
            holder.dataType.setText("Lux");
        	break;
        case Protocol.DataType.Second:
            holder.dataType.setText("Second");
        	break;
        case Protocol.DataType.Percent:
            holder.dataType.setText("Percent");
        	break;
        case Protocol.DataType.Number:
        	holder.dataType.setText("Number");
        	break;
        case Protocol.DataType.Binary:
        	holder.dataType.setText("Binary");
        default:
        	holder.dataType.setText("undefined: " + device.dataType);
        	break;
        }
        */

        return row;
    }

    static class DeviceHolder {
        TextView type;
        TextView subType;
        TextView name;
        TextView min;
        TextView max;
        TextView curValue;
        TextView dataType;
    }

}
