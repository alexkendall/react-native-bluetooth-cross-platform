package com.rctunderdark;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import io.underdark.transport.Link;

public class User {
    // public variables
    public String deviceId;
    public String displayName;
    public Link link;
    public Boolean connected = false;
    public PeerType peerType;
    enum PeerType {ADVERISER, ADVERTISER_BROWSER, BROWSER, OFFLINE};

    // constructor
    User(String id, String inName, Link inLink, Boolean inConnected, PeerType inType) {
        this.deviceId = id;
        this.link = inLink;
        this.connected = inConnected;
        this.peerType = inType;
        this.displayName = inName;
    }

    public WritableMap getJSUser() {
        WritableMap map = Arguments.createMap();
        map.putString("id", deviceId);
        map.putString("type", getStringValue(peerType));
        map.putBoolean("connected", connected);
        map.putString("name", displayName);
        return map;
    }
    public static String getStringValue(PeerType type) {
        switch (type) {
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
    public static PeerType getPeerValue(String type) {
        switch (type) {
            case "advertiser":
                return PeerType.ADVERISER;
            case "advertiserbrowser":
                return PeerType.ADVERTISER_BROWSER;
            case "browser":
                return PeerType.BROWSER;
            case "offline":
                return PeerType.BROWSER;
            default:
                return PeerType.OFFLINE;
        }
    }
}
