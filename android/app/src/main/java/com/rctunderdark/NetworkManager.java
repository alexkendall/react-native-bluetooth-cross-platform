package com.rctunderdark;
import org.w3c.dom.Node;

import io.underdark.*;
import io.underdark.transport.Link;
import io.underdark.transport.Transport;
import io.underdark.transport.TransportKind;
import io.underdark.transport.TransportListener;
import android.app.Activity;
import android.os.Debug;
import android.provider.Settings;
import android.util.Log;
import java.nio.charset.*;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import android.provider.Settings.Secure;
import android.bluetooth.BluetoothAdapter;
import java.io.UnsupportedEncodingException;
import java.util.*;
import android.provider.ContactsContract.CommonDataKinds.Phone;
import android.database.Cursor;
import android.provider.ContactsContract.Profile;

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
    private String deviceID = Settings.Secure.getString(getReactApplicationContext().getContentResolver(), Secure.ANDROID_ID);
    private String displayName = BluetoothAdapter.getDefaultAdapter().getName();
    private ReactContext context;
    private long nodeId = 0;
    // MARK: ReactContextBaseJavaModule
    public NetworkManager(ReactApplicationContext reactContext, Activity inActivity) {
        super(reactContext);
        this.activity = inActivity;
        this.context = reactContext;
        this.listener = this;
        // get display name of device
        final String[] SELF_PROJECTION = new String[] { Phone._ID,
                Phone.DISPLAY_NAME, };
        Cursor cursor = activity.getContentResolver().query(
                Profile.CONTENT_URI, SELF_PROJECTION, null, null, null);

        cursor.moveToFirst();
        displayName = cursor.getString(1);

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
                    Log.i("message", displayName);
                }
            };
            broadcastTimer = new Timer();
            broadcastTimer.schedule(tasknew, 0, 1000);
        }
    }

    // MARK: React Methods
    @ReactMethod
    public void sendMessage(String message, String id) {
        User user = findUser(id);
        if(user != null) {
            String formattedMessage = message.concat("_").concat(deviceID);
            byte[] bytes = formattedMessage.getBytes(Charset.forName("UTF-8"));
            user.link.sendFrame(bytes);
        }
    }
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
        if(nearbyUsers == null) {
            return;
        }
        WritableArray jsArray = Arguments.createArray();
        for(int i = 0; i < nearbyUsers.size(); ++i) {
            if(nearbyUsers.elementAt(i).peerType == User.PeerType.ADVERISER || nearbyUsers.elementAt(i).peerType == User.PeerType.ADVERTISER_BROWSER) {
                jsArray.pushMap(nearbyUsers.elementAt(i).getJSUser());
            }
        }
        successCallback.invoke(jsArray);
    }
    @ReactMethod
    public void inviteUser(String userId) {
        byte[] data = "invitation_".concat(deviceID).getBytes(Charset.forName("UTF-8"));
        for(int i = 0; i < nearbyUsers.size(); ++i) {
            if(nearbyUsers.elementAt(i).deviceId.equals(userId)) {
                nearbyUsers.elementAt(i).link.sendFrame(data);
            }
        }
    }
    @ReactMethod
    public void acceptInvitation(String userId) {
        User user = findUser(userId);
        if(user != null) {
            informAccepted(user);
        }
    }
    @ReactMethod
    public void disconnectFromPeer(String userId) {
        User user = findUser(userId);
        if(user != null) {
            byte[] data = "disconnected_".concat(deviceID).getBytes(Charset.forName("UTF-8"));
            user.link.sendFrame(data);
            user.connected = false;
        }
    }
    // Java Helper Functions
    private  void informConnected(User user) {
        byte[] data = "connected_".concat(deviceID).getBytes(Charset.forName("UTF-8"));
        user.link.sendFrame(data);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("connectedToUser", user.getJSUser());
    }
    private void informAccepted(User user) {
        byte[] data = "accepted_".concat(deviceID).getBytes(Charset.forName("UTF-8"));
        user.link.sendFrame(data);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("connectedToUser", user.getJSUser());
    }
    //MARK: TransportListener
    @Override
    public void transportNeedsActivity(Transport transport, ActivityCallback callback) {

    }
    @Override
    public void transportLinkConnected(Transport transport, Link link) {
        this.links.add(link);
    }
    @Override
    public void transportLinkDisconnected(Transport transport, Link link) {
        int i = 0;
        while(i < links.size()) {
            if(link.getNodeId() == links.elementAt(i).getNodeId()) {
                this.links.removeElementAt(i);
            } else {
                ++i;
            }
        }
        i = 0;
        while(i < nearbyUsers.size()) {
            if(link.getNodeId() == nearbyUsers.elementAt(i).link.getNodeId()) {
                WritableMap map = nearbyUsers.elementAt(i).getJSUser();
                map.putString("message", "lost peer");
                context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("lostUser", map);
                this.nearbyUsers.removeElementAt(i);;
            } else {
                ++i;
            }
        }
    }
    @Override
    public void transportLinkDidReceiveFrame(Transport transport, Link link, byte[] frameData) {
        try {
            if(link.getNodeId() == this.nodeId) {
                return;
            }
            User user = null;
            String message = new String(frameData, "UTF-8");
            Log.i("udark", message);
            if(containsKeyword(message)) {
                String id = getDeviceId(message);
                String keyword = getKeywordFromMessage(message);
                switch(keyword) {
                    case "advertiserbrowser_":
                        user = new User(id, link, false, User.PeerType.ADVERTISER_BROWSER);
                        checkForNewUser(user);
                        return;
                    case "advertiser_":
                        user = new User(id, link, false, User.PeerType.ADVERISER);
                        checkForNewUser(user);
                        return;
                    case "browser_":
                        user = new User(id, link, false, User.PeerType.ADVERISER);
                        checkForNewUser(user);
                        return;
                    case "invitation_":
                        user = findUser(id);
                        if(user != null) {
                            context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                                        .emit("receivedInvitation", user.getJSUser());
                        }
                        return;
                    case "accepted_":
                        user = findUser(id);
                        if(user != null) {
                            user.connected = true;
                            informConnected(user);
                        }
                        return;
                    case "connected_":
                        user = findUser(id);
                        if(user != null) {
                            user.connected = true;
                        }
                        return;
                    case "disconnected_":
                        user = findUser(id);
                        if(user != null) {
                            user.connected = false;
                        }
                    default:
                        return;

                }
            } else {
                String unformattedMessage = getUnformattedMessage(message);
                Log.i("message", unformattedMessage);
                if(unformattedMessage != null) {
                    String deviceId = message.replace(unformattedMessage, "").replace("_", "");
                    user = findUser(deviceId);
                    Log.i("message", "Device Id: ".concat(deviceId));
                    message = message.replace(deviceId, "").replace("_", "");
                    if(user != null) {
                        Log.i("message", "user is not null");
                        WritableMap map = user.getJSUser();
                        map.putString("message", message);
                        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                                .emit("messageRecieved", map);
                    }
                }
            }
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }
    private void checkForNewUser(User user) {
        Log.i("NBU", Integer.toString(nearbyUsers.size()));
        for(int i = 0; i < this.nearbyUsers.size(); ++i) {
            if(this.nearbyUsers.get(i).deviceId.equals(user.deviceId)) {
                if(nearbyUsers.get(i).peerType != user.peerType) {
                    nearbyUsers.elementAt(i).peerType = user.peerType;
                }
                return;
            }
        }
        nearbyUsers.add(user);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("detectedUser", user.getJSUser());
    }
    private boolean containsKeyword(String message) {
        String[] keywords = {"advertiserbrowser", "advertiser_", "browser_", "invitation_", "accepted_", "connected_", "disconnected_"};
        for(int i = 0; i < keywords.length; ++i) {
            if(message.contains(keywords[i])) {
                return true;
            }
        }
        return false;
    }
    private String getDeviceId(String message) {
        String[] keywords = {"advertiserbrowser_", "advertiser_", "browser_", "invitation_", "accepted_", "connected_", "advertiser", "browser", "advertiserbrowser", "disconnected_"};
        for(int i = 0; i < keywords.length; ++i) {
            if(message.contains(keywords[i])) {
                message = message.replace(keywords[i], "");
            }
        }
        return message;
    }
    private  String getKeywordFromMessage(String message) {
        String deviceId = getDeviceId(message);
        return message.replace(deviceId, "");
    }

    private String getUnformattedMessage(String message) {
        for(int i = 0; i < message.length(); ++i) {
            Character c = message.charAt(i);
            if(c.equals('_')) {
                return message.substring(0, i);
            }
        }
        return null;
    }

    private User findUser(String id) {
        for(int i = 0; i < nearbyUsers.size(); ++i) {
            if(nearbyUsers.elementAt(i).deviceId.contains(id)) {
                return nearbyUsers.elementAt(i);
            }
        }
        return null;
    }
}
