package com.rctunderdark;
import org.w3c.dom.Node;

import io.underdark.*;
import io.underdark.transport.Link;
import io.underdark.transport.Transport;
import io.underdark.transport.TransportKind;
import io.underdark.transport.TransportListener;
import android.app.Activity;
import android.os.Debug;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.*;

public class NetworkManager extends ReactContextBaseJavaModule implements TransportListener {
    // MARK: private variables
    private boolean transportConfigured = false;
    private Node node;
    private Transport transport;
    private Vector<Link> links;
    private Activity activity;

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
    }
    @ReactMethod
    public void browse(String kind) {
        initTransport(kind);
    }
    @ReactMethod
    public void stopAdvertising() {
        stopTransport();
    }
    @ReactMethod
    public void stopBrowsing() {
        stopTransport();
    }
    //MARK: TransportListener
    @Override
    public void transportNeedsActivity(Transport transport, ActivityCallback callback) {
    }
    @Override
    public void transportLinkConnected(Transport transport, Link link) {
        this.links.add(link);
        System.out.println("Link Connected");
    }

    @Override
    public void transportLinkDisconnected(Transport transport, Link link) {
        for(int i = 0; i < this.links.size(); ++i)
            if (link.getNodeId() == this.links.elementAt(i).getNodeId()) {
                this.links.removeElementAt(i);
                return;
            }
        System.out.println("Link Disconnected");
    }

    @Override
    public void transportLinkDidReceiveFrame(Transport transport, Link link, byte[] frameData) {
        System.out.println("Recieved frame");
    }
}
