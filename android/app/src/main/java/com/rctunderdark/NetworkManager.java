package com.rctunderdark;
import org.w3c.dom.Node;
import io.underdark.*;
import io.underdark.transport.Link;
import io.underdark.transport.Transport;
import io.underdark.transport.TransportKind;
import io.underdark.transport.TransportListener;
import android.app.Activity;
import android.provider.Settings;
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

public class NetworkManager extends ReactContextBaseJavaModule implements ReactNearbyUtility {
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

    // delimiters
    private String displayDelimeter = "$%#";
    private String typeDelimeter = "%$#";
    private String deviceDelimeter = "$#%";

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
        displayName = cursor.getString(1).concat("'s ").concat(android.os.Build.MODEL);

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
                    for(int i = 0; i < links.size(); ++i)
                        sendMessage(User.getStringValue(type), links.elementAt(i));
                }
            };
            broadcastTimer = new Timer();
            broadcastTimer.schedule(tasknew, 0, 1000);
        }
    }

    // MARK: React Nearby Utility Methods
    @ReactMethod
    public void sendMessage(String message, String id) {
        User user = findUser(id);
        if(user != null) {
            byte[] frame = displayName.concat(displayDelimeter).concat(User.getStringValue(this.type).concat(typeDelimeter).concat(deviceID).concat(deviceDelimeter).concat(message)).getBytes();
            user.link.sendFrame(frame);
        }
    }

    private void sendMessage(String message, Link link) {
        byte[] frame = displayName.concat(displayDelimeter).concat(User.getStringValue(this.type).concat(typeDelimeter).concat(deviceID).concat(deviceDelimeter).concat(message)).getBytes();
        link.sendFrame(frame);
        try {
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
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
            User user = findUser(userId);
            if(user != null) {
                informAccepted(user);
            }
    }
    @ReactMethod
    public void disconnectFromPeer(String userId) {
        User user = findUser(userId);
        if(user != null) {
            sendMessage("disconnected", userId);
            user.connected = false;
            WritableMap map = user.getJSUser();
            map.putString("message", "lost peer");
            context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit("lostUser", map);
        }

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
        if (link.getNodeId() == this.nodeId) {
            return;
        }
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

    private void checkForNewUser(User user) {
        if(findUser(user.deviceId) != null) {
            return;
        }
        nearbyUsers.add(user);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("detectedUser", user.getJSUser());
    }
    private User findUser(String id) {
        for (int i = 0; i < nearbyUsers.size(); ++i) {
            if (nearbyUsers.elementAt(i).deviceId.contains(id)) {
                return nearbyUsers.elementAt(i);
            }
        }
        return null;
    }

    private String getDisplayName(byte[] frame) {
        try {
            String str = new String(frame, "UTF-8");
            int displayEnd = str.indexOf(displayDelimeter);
            return str.substring(0, displayEnd);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return null;
    }
    private  User.PeerType getType(byte[] frame) {
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
    private String getDeviceId(byte[] frame) {
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
    private String getMessage(byte[] frame) {
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

    // Java Helper Functions
    private  void informConnected(User user) {
        sendMessage("connected", user.deviceId);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("connectedToUser", user.getJSUser());
        user.connected = true;
    }
    private void informAccepted(User user) {
        sendMessage("accepted", user.deviceId);
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("connectedToUser", user.getJSUser());
        user.connected = true;
    }
}
