package local.hapra.ashaappjava.ui;


import java.util.ListIterator;

import local.hapra.ashaappjava.R;
import local.hapra.ashaappjava.kernel.Device;
import local.hapra.ashaappjava.kernel.DeviceContainer;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Paint.Align;
import android.util.Log;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

/**
 * Zeigt die von Sensoren angekommene Werte in einem Zeitlichenablauf
 * aktualisiert von andbra im Feb 2020
 */
@SuppressLint("ViewConstructor")
public class HistoryView extends View {
    private int nummer;
    private Activity activity;
    Paint paint = new Paint();


    public HistoryView(Context context, Activity activity, int nummer) {
        super(context);
        this.activity = activity;
        this.nummer = nummer;
    }


    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        super.onLayout(changed, l, t, r, b);
        //Log.v("HistoryView.onLayout", String.valueOf(getWidth()) + " : " + String.valueOf(getHeight()));
    }


    @Override
    protected void onDraw(Canvas canvas) {
        //Log.v("HistoryView.onDraw", String.valueOf(getWidth()) + " : " + String.valueOf(getHeight()));

        Device device = DeviceContainer.get(nummer);
        if (device == null){
            Toast toast = Toast.makeText(activity.getApplicationContext(), "Sensor nicht gefunden", Toast.LENGTH_SHORT);
            toast.show();
            activity.finish();
        }
        assert device != null;

        float min = device.disp_min; //device.minValue;
        float max = device.disp_max; //device.maxValue;

        // Abstand vom Displayrand
        int display_min = 70;
        int display_max = getWidth() - 50;

        //Anzahl der Unteerteilungen
        int teil = 5;

        // Diagram anpassen
        if (device.bitDepth == 1){
            teil = 1;
            min = device.minValue;
            max = device.maxValue;
        }

        paint.setColor(Color.WHITE);

        // @andbra sp anstatt px
        paint.setTextSize(textSpToPx(11));

        //Log.v("HistoryView.onDraw2", String.valueOf(canvas.getWidth()) + " : " + String.valueOf(canvas.getHeight()));

        //Hintergrundfarbe bestimmen
        canvas.drawColor(Color.rgb(64, 64, 64));
        //View drehen
        canvas.rotate(90);
        canvas.translate(0, -getWidth());
        // Achse zeichnen
        canvas.drawLine(100, 0, 100, getWidth(), paint);

        //Unterteilungen zeichnen
        for (float i = 0; i <= 1; i += (1.0 / teil)) {
            float value = (1 - i) * min + i * max;

            value = (float) Math.round(value * 100) / 100;
            //value = parser
            float startY = (1 - i) * display_max + i * display_min;
            canvas.drawText("" + value, 100, startY, paint);

            // @andbra getHeight anstatt 700px
            canvas.drawLine(100, startY,getHeight(), startY, paint);
        }

        // Werte anzeigen
        paint.setColor(Color.GREEN);
        synchronized (device.getHistory()) {
            final ListIterator<Float> iterator = device.getHistory().listIterator(device.getHistory().size());
            int i = 0;

            while (iterator.hasPrevious()) {
                float value = iterator.previous();
                float alpha = (value - min) / (max - min);

                if (alpha == 0) {
                    alpha = getWidth() - 51;
                } else {
                    alpha = (1 - alpha) * (getWidth() - 50) + alpha * 50;
                }


                canvas.drawLine(100 + i, getWidth() - 50,
                        100 + i, alpha, paint);
                i++;
            }
        }
        int spSize = 17;
        float scaledSizeInPixels = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP,
                spSize, getResources().getDisplayMetrics());


        paint.setColor(Color.WHITE);
        paint.setTextAlign(Align.CENTER);
        // @andbra sp anstatt px
        paint.setTextSize(textSpToPx(18));
        canvas.drawText(getResources().getString(R.string.time), Math.round(getHeight() / 2f), getWidth() - 10, paint);

        super.onDraw(canvas);
    }

    /**
     * Umrechnung der Textgröße von sp nach px anhand der Display- DPI
     * @param sp
     * @return
     */
    private float textSpToPx(int sp){
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sp, getResources().getDisplayMetrics());
    }
}
