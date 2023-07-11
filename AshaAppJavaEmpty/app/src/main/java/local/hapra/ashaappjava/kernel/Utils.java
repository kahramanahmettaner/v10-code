package local.hapra.ashaappjava.kernel;

import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.Configuration;
import android.content.res.Resources;

import java.util.ArrayList;
import java.util.Locale;

/**
 * Ändert die Sprache
 * hinzugefügt iim Feb2020 von andbra
 */
public class Utils {


    private static String currentLocaleCode = "de";

    private static ArrayList<String> locales = new ArrayList<String>() {{
        add("en");
        add("de");
    }};

    public static void setCurrentLocale(String langCode){
        if(locales.contains(langCode)){
            currentLocaleCode = langCode;
        }

    }

    /**
     * Ändert die Sprache
     * In Anlehnung an https://stackoverflow.com/questions/39705739/android-n-change-language-programmatically/40849142#40849142
     */
    public static ContextWrapper changeLang(Context context){

        Resources resources = context.getResources();
        Configuration config = resources.getConfiguration();

        Locale sysLocale = config.getLocales().get(0);
        Locale locale = new Locale(currentLocaleCode);

        Locale.setDefault(locale);
        config.setLocale(locale);

        context = context.createConfigurationContext(config);

        return new ContextWrapper(context);
    }
}
