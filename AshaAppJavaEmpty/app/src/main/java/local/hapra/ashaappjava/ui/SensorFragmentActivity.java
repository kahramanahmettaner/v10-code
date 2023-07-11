package local.hapra.ashaappjava.ui;


import android.os.Bundle;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import androidx.viewpager2.widget.ViewPager2;

import local.hapra.ashaappjava.R;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;

/**
 * Zeigt Details und History eines Sensors durch zwei Fragmente an.
 *  * hinzugefügt von andbra im Feb 2020
 * in Anlehnung an
 * https://developer.android.com/training/animation/screen-slide-2
 * https://developer.android.com/guide/navigation/navigation-swipe-view-2
 */
@SuppressWarnings("FieldCanBeLocal")
public class SensorFragmentActivity extends FragmentActivity {

    private FragmentStateAdapter pagerAdapter;

    private ViewPager2 viewPagerSensors;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // TODO Auto-generated method stub
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sensors);


        viewPagerSensors = findViewById(R.id.viewPagerSensors);

        pagerAdapter = new ScreenSlidePagerAdapter(this);
        viewPagerSensors.setAdapter(pagerAdapter);

        // TabLayout im Kopfbereich
        TabLayout tabLayoutSensors = findViewById(R.id.tabLayoutSensors);
        new TabLayoutMediator(tabLayoutSensors, viewPagerSensors, new TabLayoutMediator.TabConfigurationStrategy() {
            @Override
            public void onConfigureTab(@NonNull TabLayout.Tab tab, int position) {
                switch (position){
                    case 0 :
                        tab.setText(R.string.tabDevice);
                        tab.setIcon(android.R.drawable.ic_menu_info_details);
                        break;
                    case 1 :
                        tab.setText(R.string.tabHistory);
                        tab.setIcon(android.R.drawable.ic_menu_recent_history);
                        break;
                }
            }
        }).attach();

    }

    @Override
    public void onBackPressed() {
        if (viewPagerSensors.getCurrentItem() == 0) {
            super.onBackPressed();
        } else {
            // Otherwise, select the previous step.
            viewPagerSensors.setCurrentItem(viewPagerSensors.getCurrentItem() - 1);
        }
    }


    private static class ScreenSlidePagerAdapter extends FragmentStateAdapter {
        private int NUM_PAGES = 2;
        public ScreenSlidePagerAdapter(FragmentActivity fragmentActivity) {
            super(fragmentActivity);
        }

        @NonNull
        @Override
        public Fragment createFragment(int position) {
            Log.v("createFragment", String.valueOf(position));
            if (position == 1) {
                return new HistoryFragment();
            }
            return new DeviceFragment();
        }

        @Override
        public int getItemCount() {
            return NUM_PAGES;
        }
    }

}

