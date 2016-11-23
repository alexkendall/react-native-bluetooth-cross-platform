package com.rctunderdark;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactMethod;

public interface ReactNearbyInterface {
    @ReactMethod
    public void sendMessage(String message, String id);

    @ReactMethod
    public void advertise(String kind);

    @ReactMethod
    public void browse(String kind);

    @ReactMethod
    public void stopAdvertising();

    @ReactMethod
    public void stopBrowsing();

    @ReactMethod
    public void getConnectedPeers(Callback successCallback);

    @ReactMethod
    public void getNearbyPeers(Callback successCallback);

    @ReactMethod
    public void inviteUser(String userId);

    @ReactMethod
    public void acceptInvitation(String userId);

    @ReactMethod
    public void disconnectFromPeer(String userId);
}
