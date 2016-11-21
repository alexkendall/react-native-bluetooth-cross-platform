package com.rctunderdark;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;

import java.util.Vector;

public class NetworkManager extends ReactContextBaseJavaModule implements ReactNearbyInterface {
    // MARK: private variables
    private User.PeerType type = User.PeerType.OFFLINE;
    private  NetworkCommunicator networkCommunicator;

    // MARK: ReactContextBaseJavaModule
    public NetworkManager(ReactApplicationContext reactContext) {
        super(reactContext);
        this.networkCommunicator = new NetworkCommunicator(reactContext);
    }
    @Override
    public String getName() {
        return "NetworkManager";
    }

    // MARK: React Nearby Utility Methods
    @ReactMethod
    public void sendMessage(String message, String id) {
        this.networkCommunicator.sendMessage(message, id);
    }
    @ReactMethod
    public void advertise(String kind) {
        if(this.type == User.PeerType.BROWSER) {
            this.type = User.PeerType.ADVERTISER_BROWSER;
        } else {
            this.type = User.PeerType.ADVERISER;
        }
        this.networkCommunicator.initTransport(kind, this.type);
    }
    @ReactMethod
    public void browse(String kind) {
        if(this.type == User.PeerType.ADVERISER) {
            this.type = User.PeerType.ADVERTISER_BROWSER;
        } else {
            this.type = User.PeerType.BROWSER;
        }
        this.networkCommunicator.initTransport(kind, this.type);
    }

    @ReactMethod
    public void stopAdvertising() {
        if(this.type == User.PeerType.ADVERTISER_BROWSER) {
            this.type = User.PeerType.BROWSER;
            this.networkCommunicator.initTransport("WIFI-BT", this.type);
            return;
        }
        this.type = User.PeerType.OFFLINE;
        this.networkCommunicator.stopTransport();
    }
    @ReactMethod
    public void stopBrowsing() {
        if(this.type == User.PeerType.ADVERTISER_BROWSER) {
            this.type = User.PeerType.ADVERISER;
            this.networkCommunicator.initTransport("WIFI-BT", this.type);
            return;
        }
        this.type = User.PeerType.OFFLINE;
        this.networkCommunicator.stopTransport();
    }
    @ReactMethod
    public void getConnectedPeers(Callback successCallback) {
        Vector<User> connectedPeers = new Vector<User>();
        Vector<User> nearbyUsers = networkCommunicator.nearbyUsers;
        for(int i = 0; i < nearbyUsers.size(); ++i) {
            if(nearbyUsers.get(i).connected) {
                connectedPeers.add(nearbyUsers.get(i));
            }
        }
        WritableArray jsArray = Arguments.createArray();
        for(int i = 0; i < connectedPeers.size(); ++i) {
            jsArray.pushMap(connectedPeers.elementAt(i).getJSUser());
        }
        successCallback.invoke(jsArray);
    }
    @ReactMethod
    public void getNearbyPeers(Callback successCallback) {
        Vector<User> nearbyUsers = networkCommunicator.nearbyUsers;
        if(nearbyUsers == null) {
            return;
        }
        WritableArray jsArray = Arguments.createArray();
        for(int i = 0; i < nearbyUsers.size(); ++i) {
            jsArray.pushMap(nearbyUsers.elementAt(i).getJSUser());
        }
        successCallback.invoke(jsArray);
    }
    @ReactMethod
    public void inviteUser(String userId) {
        sendMessage("invitation", userId);
    }

    @ReactMethod
    public void acceptInvitation(String userId) {
        User user = networkCommunicator.findUser(userId);
        if(user != null) {
            networkCommunicator.informAcceptedInvite(user);
        }
    }
    @ReactMethod
    public void disconnectFromPeer(String userId) {
        User user = networkCommunicator.findUser(userId);
        if(user != null) {
            user.connected = false;
            networkCommunicator.informDisconnected(user);
        }
    }
}
