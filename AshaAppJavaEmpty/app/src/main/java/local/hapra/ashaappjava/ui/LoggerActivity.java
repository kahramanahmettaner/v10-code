package local.hapra.ashaappjava.ui;


import android.content.Context;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ListView;

import androidx.appcompat.app.AppCompatActivity;

import local.hapra.ashaappjava.R;
import local.hapra.ashaappjava.kernel.Logger;
import local.hapra.ashaappjava.kernel.Utils;

/**
 * Speichert und zeigt alle interne Prozesse in der App (zum Debuggen, Analyse)
 * Updated von andbra im Feb 2020
 * @author Viktor
 *
 */
public class LoggerActivity extends AppCompatActivity {
    private static ArrayAdapter<String> logArrayAdapter;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_logger);

        logArrayAdapter = new ArrayAdapter<>(this, R.layout.loggerlistlayout, Logger.getLogs());

        ListView logList = findViewById(R.id.logList);

        logList.setAdapter(logArrayAdapter);

        Button btnClear = findViewById(R.id.btnClear);
        btnClear.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Logger.clearLogs();
                logArrayAdapter.notifyDataSetChanged();
            }
        });

        Button btnBack = findViewById(R.id.btnBack);
        btnBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

    }


    /**
     * Ändern den Context in die gewünschte Sprache
     * Created by andbra
     */
    @Override
    protected void attachBaseContext(Context oldContext) {
        Context context = Utils.changeLang(oldContext);
        super.attachBaseContext(context);
    }



}