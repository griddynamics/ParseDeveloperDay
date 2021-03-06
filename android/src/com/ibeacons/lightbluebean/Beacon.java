package com.ibeacons.lightbluebean;

import android.bluetooth.BluetoothDevice;
import com.ibeacons.beaconinterface.IBeacon;
import nl.littlerobots.bean.Bean;

public class Beacon implements IBeacon {

    private Bean bean;
    private int rssi;
    private String roomName;

    public Beacon(Bean bean, int rssi, String roomName) {
        this.bean = bean;
        this.rssi = rssi;
        this.roomName = roomName;
    }

    public Beacon(Bean bean, int rssi) {
        this.bean = bean;
        this.rssi = rssi;
    }

    @Override
    public String getRoomName() {
        return roomName;
    }

    @Override
    public String getName() {
        return bean.getDevice().getName();
    }

    @Override
    public String getAddress() {
        return bean.getDevice().getAddress();
    }

    @Override
    public BluetoothDevice getDevice() {
        return bean.getDevice();
    }

    @Override
    public Bean getBean() {
        return bean;
    }

    @Override
    public int getRssi() {
        return rssi;
    }

    @Override
    public int compareTo(IBeacon another) {
        return another.getRssi() < rssi  ? -1 : (rssi == another.getRssi() ? 0 : 1);
    }
}