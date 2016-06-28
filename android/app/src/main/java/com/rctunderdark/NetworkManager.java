package com.rctunderdark;
import org.w3c.dom.Node;

import io.underdark.*;
import io.underdark.transport.Link;
import io.underdark.transport.Transport;
import io.underdark.transport.TransportKind;
import io.underdark.transport.TransportListener;
import android.app.Activity;
import android.os.Debug;
import android.util.Log;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

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

    // MARK: ReactContextBaseJavaModule
    public NetworkManager(ReactApplicationContext reactContext, Activity inActivity) {
        super(reactContext);
        this.activity = inActivity;
    }

    @Override
    public String getName() {
        return "NetworkManager";
    }

    private void initTransport(String kind) {
        if(transportConfigured){
            return;
        }
        this.listener = this;
        links = new Vector<Link>();
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
    }
    private void stopTransport() {
        transport.stop();
    }

    // MARK: React Methods
    @ReactMethod
    public void advertise(String kind) {
        initTransport(kind);
        if(this.type == User.PeerType.BROWSER) {
            this.type = User.PeerType.ADVERTISER_BROWSER;
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
        } else {
            this.type = User.PeerType.OFFLINE;
        }
        stopTransport();
    }
    @ReactMethod
    public void stopBrowsing() {
        if(this.type == User.PeerType.ADVERTISER_BROWSER) {
            this.type = User.PeerType.ADVERISER;
        } else {
            this.type = User.PeerType.OFFLINE;
        }
        stopTransport();
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
        Log.d("NetworkManager", "Received frame");
        try {
            String message = new String(frameData, "UTF-8");
            String id = "";
            Boolean connected = false;
            User.PeerType peerType = User.PeerType.OFFLINE;
            if(message.contains("advertiserbrowser_")) {
                peerType = User.PeerType.ADVERTISER_BROWSER;
                message = message.replace("advertiserbrowser_", "");
            } else if(message.contains("advertiser_")) {
                peerType = User.PeerType.ADVERISER;
                message = message.replace("advertiser_", "");
            } else if(message.contains("browser_")) {
                peerType = User.PeerType.BROWSER;
                message = message.replace("browser_", "");
            }
            User user = new User(id, link, connected, peerType);
            for(int i = 0; i < this.nearbyUsers.size(); ++i) {
                if(this.nearbyUsers.get(i).link.getNodeId() == link.getNodeId()) {
                    this.nearbyUsers.removeElementAt(i);
                }
            }
            nearbyUsers.add(user);
            Log.d("User ID", message);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }
}
