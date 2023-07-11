package local.hapra.ashaappjava.ui;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import local.hapra.ashaappjava.R;

/**
 * Sensor History Oberflächenfragment
 * @author andbra
 */
public class HistoryFragment extends Fragment {
    private HistoryView historyView = null;


    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_sensor_history, container, false);

        Activity activity = getActivity();
        assert activity != null;

        Bundle bundle = activity.getIntent().getExtras();
        assert bundle != null;
        int nummer = bundle.getInt("DeviceNummer", 0);

        Log.v("HistoryView1", String.valueOf(view.getWidth()) + " : " + view.getHeight());

        historyView  = new HistoryView(view.getContext(), activity, nummer);

        LinearLayout layout = (LinearLayout) view.findViewById(R.id.linearLayoutHistory);
        layout.addView(historyView);

        return view;
    }

    @Override
    public void onViewCreated(@NonNull View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        Log.v("HistoryView2", view.getWidth() + " : " + view.getHeight());

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

    //empfaengt Nachrichten wenn neuer Wert hinzugefuegt wurde und aktualisiert View
    private final BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            if (action != null && action.equals("VALUECHANGED")) {
                //Log.v("HistoryView", "BroadcastReceiver.onReceive");
                historyView.invalidate();
                historyView.refreshDrawableState();
            }
        }
    };


}
