package local.hapra.ashaappjava.kernel;

import android.util.Log;

import java.util.ArrayList;
import java.util.List;

/**
 * Speichert die Log-Einträge (zum Debuggen, Analyse)
 * Created by andbra on Feb 2020
 *
 */
public class Logger {
    private static List<String> logs = new ArrayList<>();

    /**
     * Einfügen von neuen Erreignissen
     * @param log log
     */
    public static void add(String log) {
        logs.add(log);
        Log.v("Test", log);
    }

    public static List<String> getLogs(){
        return logs;
    }

    public static void clearLogs(){
       logs.clear();
    }

}
