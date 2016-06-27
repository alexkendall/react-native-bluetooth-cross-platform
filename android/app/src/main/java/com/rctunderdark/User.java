package com.rctunderdark;

import android.util.Log;

import com.facebook.react.bridge.ReadableMap;

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

    public Map<String, Object> getJSUser() {
        final Map<String, Object> map = new HashMap<>();
        map.put("id", this.deviceId);
        map.put("connected", this.connected);
        map.put("type", getStringValue(this.peerType));
        return map;
    }

    public String getStringValue(PeerType type) {
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
