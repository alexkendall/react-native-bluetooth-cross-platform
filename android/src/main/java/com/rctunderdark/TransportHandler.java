package com.rctunderdark;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.EnumSet;
import java.util.Random;
import java.util.Vector;

import io.underdark.Underdark;
import io.underdark.transport.Link;
import io.underdark.transport.Transport;
import io.underdark.transport.TransportKind;
import io.underdark.transport.TransportListener;

public class TransportHandler implements TransportListener {
    // MARK: private variables
    private boolean transportConfigured = false;
    private Transport transport;
    protected Vector<Link> links;
    protected Vector<User> nearbyUsers;
    private TransportListener listener;
    protected ReactContext context;
    private long nodeId = 0;

    // MARK: ReactContextBaseJavaModule
    public TransportHandler(ReactApplicationContext reactContext) {
        this.context = reactContext;
        this.listener = this;
    }
    public void initTransport(String kind, User.PeerType inType) {
        if(transportConfigured){
            transport.start();
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
            kinds = EnumSet.of(TransportKind.WIFI);

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
                context,
                kinds
        );
        this.transportConfigured = true;
        transport.start();
    }
    public void stopTransport() {
        transport.stop();
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
            if (link.getNodeId() != nearbyUsers.elementAt(i).link.getNodeId()) {
                ++i;
            } else {
                WritableMap map = nearbyUsers.elementAt(i).getJSUser();
                map.putString("message", "lost peer");
                context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("lostUser", map);
                this.nearbyUsers.removeElementAt(i);;
            }
        }
    }
    @Override
    public void transportLinkDidReceiveFrame(Transport transport, Link link, byte[] frameData) {
        if (link.getNodeId() == this.nodeId) {
            return;
        }
        // handle this in network communicatorwith proper encoder and decoder functionality
    }
}
