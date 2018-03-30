package com.rctunderdark;

import android.bluetooth.BluetoothAdapter;
import android.provider.Settings;
import android.provider.Settings.Secure;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.UnsupportedEncodingException;
import java.util.Timer;
import java.util.TimerTask;

import io.underdark.transport.Link;
import io.underdark.transport.Transport;

public class NetworkCommunicator extends TransportHandler implements MessageDecoder, MessageEncoder {

    // delimiters
    private String displayDelimeter = "$%#";
    private String typeDelimeter = "%$#";
    private String deviceDelimeter = "$#%";
    private String deviceID = Settings.Secure.getString(context.getContentResolver(), Secure.ANDROID_ID);
    private String displayName;
    private Timer broadcastTimer = null;
    private Boolean isRunning = false;
    private User.PeerType type = User.PeerType.OFFLINE;

    // INITIALIAZATION
    public NetworkCommunicator(ReactApplicationContext reactContext) {
        super(reactContext);
        if (BluetoothAdapter.getDefaultAdapter() != null) {
            displayName = BluetoothAdapter.getDefaultAdapter().getName();
        }
    }

    @Override
    public void transportLinkDidReceiveFrame(Transport transport, Link link, byte[] frameData) {
        super.transportLinkDidReceiveFrame(transport, link, frameData);
        String message = getMessage(frameData);
        String id = getDeviceId(frameData);
        if(id.equals(this.deviceID)) {
            return;
        }
        User.PeerType type = getType(frameData);
        String displayName = getDisplayName(frameData);
        User user = null;
        switch (message) {
            case "advertiserbrowser":
                user = new User(id, displayName, link, false, type);
                checkForNewUser(user);
                return;
            case "advertiser":
                user = new User(id, displayName, link, false, type);
                checkForNewUser(user);
                return;
            case "browser":
                user = new User(id, displayName, link, false, type);
                checkForNewUser(user);
                return;
            case "invitation":
                user = findUser(id);
                if (user != null) {
                    context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                            .emit("receivedInvitation", user.getJSUser());
                }
                return;
            case "accepted":
                user = findUser(id);
                if (user != null) {
                    user.connected = true;
                    informConnected(user);
                }
                return;
            case "connected":
                user = findUser(id);
                if (user != null) {
                    user.connected = true;
                }
                return;
            case "disconnected":
                user = findUser(id);
                if (user != null) {
                    user.connected = false;
                }
                WritableMap map = user.getJSUser();
                map.putString("message", "lost peer");
                context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("lostUser", map);
                return;
            default:
                user = findUser(id);
                if (user != null){
                    WritableMap messageMap = user.getJSUser();
                    messageMap.putString("message", message);
                    context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                            .emit("messageReceived", messageMap);
                }
        }
    }

    @Override
    public void initTransport(String kind, User.PeerType inType) {
        super.initTransport(kind, inType);
        this.type = inType;
        broadcastType();
    }

    @Override
    public void stopTransport() {
        if (broadcastTimer != null) {
            broadcastTimer.cancel();
        }
        broadcastTimer = null;
        isRunning = false;
    }

    @Override
    public String getDisplayName(byte[] frame) {
        try {
            String str = new String(frame, "UTF-8");
            int displayEnd = str.indexOf(displayDelimeter);
            return str.substring(0, displayEnd);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public User.PeerType getType(byte[] frame) {
        try {
            String str = new String(frame, "UTF-8");
            int typeStart = str.indexOf(displayDelimeter);
            int typeEnd = str.indexOf(typeDelimeter);
            String strType = str.substring(typeStart, typeEnd);
            return User.getPeerValue(strType);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public String getDeviceId(byte[] frame) {
        try {
            String str = new String(frame, "UTF-8");
            int displayStart = str.indexOf(typeDelimeter) + deviceDelimeter.length();
            int displayEnd = str.indexOf(deviceDelimeter);
            return str.substring(displayStart, displayEnd);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public String getMessage(byte[] frame) {
        try {
            String str = new String(frame, "UTF-8");
            int messageStart = str.indexOf(deviceDelimeter);
            if(messageStart != -1) {
                return str.substring(messageStart + deviceDelimeter.length(), str.toCharArray().length);
            }
            return "index out of range";
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public void informConnected(User user) {
        user.connected = true;
        sendMessage("connected", user.deviceId);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("connectedToUser", user.getJSUser());
    }

    @Override
    public void informAccepted(User user) {
        user.connected = true;
        sendMessage("accepted", user.deviceId);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("connectedToUser", user.getJSUser());
    }

    @Override
    public void informDisconnected(User user) {
        user.connected = false;
        sendMessage("disconnected", user.deviceId);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("lostUser", user.getJSUser());
    }

    @Override
    public void informAcceptedInvite(User user) {
        user.connected = true;
        sendMessage("accepted", user.deviceId);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("connectedToUser", user.getJSUser());
    }

    @Override
    public void inviteUser(User user) {
        sendMessage("invitation", user.deviceId);
    }

    @Override
    public void broadcastType() {
        if(!isRunning) {
            // creating timer task, timer
            TimerTask tasknew = new TimerTask() {
                @Override
                public void run() {
                    isRunning = true;
                    for(int i = 0; i < links.size(); ++i)
                        sendMessage(User.getStringValue(type), links.elementAt(i));
                }
            };
            broadcastTimer = new Timer();
            broadcastTimer.schedule(tasknew, 0, 1000);
        }
    }

    @Override
    public void sendMessage(String message, Link link) {
        byte[] frame = displayName.concat(displayDelimeter).concat(User.getStringValue(this.type).concat(typeDelimeter).concat(deviceID).concat(deviceDelimeter).concat(message)).getBytes();
        link.sendFrame(frame);
    }

    @Override
    public void sendMessage(String message, String id) {
        User user = findUser(id);
        if(user != null) {
            byte[] frame = displayName.concat(displayDelimeter).concat(User.getStringValue(this.type).concat(typeDelimeter).concat(deviceID).concat(deviceDelimeter).concat(message)).getBytes();
            user.link.sendFrame(frame);
        }
    }

    // UTILITY
    public User findUser(String id) {
        for (int i = 0; i < nearbyUsers.size(); ++i) {
            if (nearbyUsers.elementAt(i).deviceId.contains(id)) {
                return nearbyUsers.elementAt(i);
            }
        }
        return null;
    }
    private void checkForNewUser(User user) {
        if(findUser(user.deviceId) != null) {
            return;
        }
        nearbyUsers.add(user);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("detectedUser", user.getJSUser());
    }
}
