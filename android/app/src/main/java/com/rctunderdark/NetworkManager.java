package com.rctunderdark;
import org.w3c.dom.Node;

import io.underdark.*;
import io.underdark.transport.Link;
import io.underdark.transport.Transport;
import io.underdark.transport.TransportKind;
import io.underdark.transport.TransportListener;
import android.app.Activity;
import android.os.Debug;
import android.provider.Telephony;
import android.util.Log;

import java.lang.reflect.Array;
import java.nio.charset.*;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.UnsupportedEncodingException;
import java.util.*;

public class NetworkManager extends ReactContextBaseJavaModule implements TransportListener {
    // MARK: private variables
    private boolean transportConfigured = false;
    private Node node;
    private Transport transport;
    private Vector<Link> links;
    private Vector<User> nearbyUsers;
    private Activity activity;
    private TransportListener listener;
    private User.PeerType type = User.PeerType.OFFLINE;
    private Timer broadcastTimer;
    private Boolean isRunning = false;
    private String deviceID = UUID.randomUUID().toString();;
    private ReactContext context;
    // MARK: ReactContextBaseJavaModule
    public NetworkManager(ReactApplicationContext reactContext, Activity inActivity) {
        super(reactContext);
        this.activity = inActivity;
        this.context = reactContext;
        this.listener = this;
    }
    @Override
    public String getName() {
        return "NetworkManager";
    }

    private void initTransport(String kind) {
        if(transportConfigured){
            transport.start();
            this.broadcastType();
            return;
        }
        this.listener = this;
        links = new Vector<Link>();
        nearbyUsers = new Vector<User>();
        long nodeId = 0;
        while(nodeId == 0) {
            nodeId = new Random().nextLong();
        }
        EnumSet<TransportKind> kinds = null;
        if(nodeId < 0) {
            nodeId = -nodeId;
        }

        if("WIFI".equals(kind)) {
            EnumSet.of(TransportKind.WIFI);

        } else if("BT".equals(kind)) {
            kinds = EnumSet.of(TransportKind.BLUETOOTH);

        } else {
            kinds = EnumSet.of(TransportKind.WIFI, TransportKind.BLUETOOTH);
    }
        this.transport = Underdark.configureTransport(
                234235,
                nodeId,
                this,
                null,
                activity.getApplicationContext(),
                kinds
        );
        this.transportConfigured = true;
        transport.start();
        this.broadcastType();
    }
    private void stopTransport() {
        transport.stop();
        broadcastTimer.cancel();
        isRunning = false;
    }

    public void broadcastType() {
        if(!isRunning) {
            // creating timer task, timer
            TimerTask tasknew = new TimerTask() {
                @Override
                public void run() {
                    isRunning = true;
                    String broadcast = User.getStringValue(type).concat("_").concat(deviceID);
                    //Log.d("Broadcast", broadcast);
                    for(int i = 0; i < links.size(); ++i) {
                        byte[] bytes = broadcast.getBytes(Charset.forName("UTF-8"));
                        Link link = links.get(i);
                        link.sendFrame(bytes);
                    }
                }
            };
            broadcastTimer = new Timer();
            broadcastTimer.schedule(tasknew, 0, 1000);
        }
    }

    // MARK: React Methods
    @ReactMethod
    public void advertise(String kind) {
        initTransport(kind);
        if(this.type == User.PeerType.BROWSER) {
            this.type = User.PeerType.ADVERTISER_BROWSER;
        } else {
            this.type = User.PeerType.ADVERISER;
        }
        this.initTransport(kind);
    }
    @ReactMethod
    public void browse(String kind) {
        if(this.type == User.PeerType.ADVERISER) {
            this.type = User.PeerType.ADVERTISER_BROWSER;
        } else {
            this.type = User.PeerType.BROWSER;
        }
        initTransport(kind);
    }

    @ReactMethod
    public void stopAdvertising() {
        if(this.type == User.PeerType.ADVERTISER_BROWSER) {
            this.type = User.PeerType.BROWSER;
            return;
        }
        this.type = User.PeerType.OFFLINE;
        stopTransport();
    }
    @ReactMethod
    public void stopBrowsing() {
        if(this.type == User.PeerType.ADVERTISER_BROWSER) {
            this.type = User.PeerType.ADVERISER;
            return;
        }
        this.type = User.PeerType.OFFLINE;
        stopTransport();
    }
    @ReactMethod
    public void getConnectedPeers(Callback successCallback) {
        Vector<User> connectedPeers = new Vector<User>();
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
        WritableArray jsArray = Arguments.createArray();
        for(int i = 0; i < nearbyUsers.size(); ++i) {
            jsArray.pushMap(nearbyUsers.elementAt(i).getJSUser());
        }
        successCallback.invoke(jsArray);
    }
    @ReactMethod
    public void inviteUser(String userId) {
        byte[] data = "invitation_".concat(deviceID).concat(User.getStringValue(type)).getBytes(Charset.forName("UTF-8"));
        for(int i = 0; i < nearbyUsers.size(); ++i) {
            Log.i("Device Id",nearbyUsers.elementAt(i).deviceId);
            if(nearbyUsers.elementAt(i).deviceId.equals(userId)) {
                Log.i("Invite User", userId);
                nearbyUsers.elementAt(i).link.sendFrame(data);
            }
        }
    }
    //MARK: TransportListener
    @Override
    public void transportNeedsActivity(Transport transport, ActivityCallback callback) {

    }
    @Override
    public void transportLinkConnected(Transport transport, Link link) {
        this.links.add(link);
        Log.d("NetworkManager", "Link Connected");
    }

    @Override
    public void transportLinkDisconnected(Transport transport, Link link) {
        for(int i = 0; i < this.links.size(); ++i)
            if (link.getNodeId() == this.links.elementAt(i).getNodeId()) {
                this.links.removeElementAt(i);
                return;
            }
        Log.d("NetworkManager", "Link Disconnected");
    }

    @Override
    public void transportLinkDidReceiveFrame(Transport transport, Link link, byte[] frameData) {
        //Log.d("NetworkManager", "Received frame");
        try {
            String message = new String(frameData, "UTF-8");
            String id = "";
            Boolean connected = false;
            User.PeerType peerType = User.PeerType.OFFLINE;
            if(message.contains("advertiserbrowser_")) {
                peerType = User.PeerType.ADVERTISER_BROWSER;
                id = message.replace("advertiserbrowser_", "");
            } else if(message.contains("advertiser_")) {
                peerType = User.PeerType.ADVERISER;
                id = message.replace("advertiser_", "");
            } else if(message.contains("browser_")) {
                peerType = User.PeerType.BROWSER;
                id = message.replace("browser_", "");
            }
            User user = new User(id, link, connected, peerType);
            for(int i = 0; i < this.nearbyUsers.size(); ++i) {
                if(this.nearbyUsers.get(i).link.getNodeId() == link.getNodeId()) {
                    this.nearbyUsers.removeElementAt(i);
                }
            }
            nearbyUsers.add(user);
            context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("detectedUser", user.getJSUser());
            //Log.d("User ID", message);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }
}
