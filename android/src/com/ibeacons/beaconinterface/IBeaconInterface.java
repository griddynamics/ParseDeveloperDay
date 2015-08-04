package com.ibeacons.beaconinterface;

import android.app.Activity;

import java.util.List;

public interface IBeaconInterface {

    void startScanning(Activity activity);

    void stopScanning();

    List<IBeacon> getIBeacons();

}
