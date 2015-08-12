package com.ibeacons.lightbluebean;

import android.app.Activity;
import android.database.Cursor;
import com.ibeacons.beaconinterface.IBeacon;
import com.ibeacons.beaconinterface.IBeaconInterface;
import nl.littlerobots.bean.Bean;
import nl.littlerobots.bean.BeanDiscoveryListener;
import nl.littlerobots.bean.BeanManager;

import java.util.*;

public class IBeaconManager implements IBeaconInterface {

    private static volatile IBeaconManager instance;
    private static BeanDiscoveryListener beanDiscoveryListener;
    private List<IBeacon> iBeacons = new ArrayList<IBeacon>();
    private static final long SCAN_DELAY = 4000L;
    private static final long TIMER_DELAY = 1000L;
    private Timer mTimer;
    Activity activity;

    public static IBeaconManager getInstance() {
        IBeaconManager localInstance = instance;
        if (localInstance == null) {
            synchronized (IBeaconManager.class) {
                localInstance = instance;
                if (localInstance == null) {
                    instance = localInstance = new IBeaconManager();
                }
            }
        }
        return localInstance;
    }

    public void startScanning(final Activity activity) {
        android.util.Log.w("test", "in start THREAD:" + Thread.currentThread().getName());

        beanDiscoveryListener = new BeanDiscoveryListener() {
            private List<IBeacon> tempIBeacon = new ArrayList<IBeacon>();

            @Override
            public void onBeanDiscovered(Bean bean, int rssi, List<UUID> list) {
                 tempIBeacon.add(new Beacon(bean, rssi));
            }

            @Override
            public void onDiscoveryComplete() {
                iBeacons.clear();
                iBeacons.addAll(tempIBeacon);
                tempIBeacon.clear();
            }
        };

        mTimer = new Timer();
        BeanUpdateTimerTask mTimerTask = new BeanUpdateTimerTask();
        BeanManager.setScanTimeout(SCAN_DELAY);
        mTimer.schedule(mTimerTask, 0, SCAN_DELAY + TIMER_DELAY);
    }

    class BeanUpdateTimerTask extends TimerTask {
        @Override
        public void run() {
            BeanManager.getInstance().startDiscovery(beanDiscoveryListener);
        }
    }

    public List<IBeacon> getIBeacons() {
        Collections.sort(iBeacons);
        return iBeacons;
    }

    public void stopScanning() {
        android.util.Log.w("test", "in stop THREAD:" + Thread.currentThread().getName());
        mTimer.cancel();
        mTimer.purge();
        BeanManager.getInstance().cancelDiscovery();
    }

    public List<String> getIBeaconsAddresses() {
        List<IBeacon> iBeacons = getIBeacons();
        List<String> iBeaconsAddresses = new ArrayList<String>();
        for(IBeacon b : iBeacons) {
            iBeaconsAddresses.add(b.getAddress());
        }
        return iBeaconsAddresses;
    }

}