package com.rctunderdark;

import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.util.Map;
import java.util.HashMap;

import io.underdark.transport.Link;

public class User {
    // public variables
    public String deviceId;
    public Link link;
    public Boolean connected = false;
    public PeerType peerType;
    enum PeerType {ADVERISER, ADVERTISER_BROWSER, BROWSER, OFFLINE};

    // constructor
    User(String id, Link inLink, Boolean inConnected, PeerType inType) {
        this.deviceId = id;
        this.link = inLink;
        this.connected = inConnected;
        this.peerType = inType;
    }

    public WritableMap getJSUser() {
        WritableMap map = Arguments.createMap();
        map.putString("id", deviceId);
        map.putString("type", getStringValue(peerType));
        map.putBoolean("connected", connected);
        return map;
    }

    public static String getStringValue(PeerType type) {
        switch(type) {
            case ADVERISER:
                return "advertiser";
            case ADVERTISER_BROWSER:
                return "advertiserbrowser";
            case BROWSER:
                return "browser";
            case OFFLINE:
                return "offline";
            default:
                return "";
        }
    }
}
