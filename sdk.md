# Javascript SDK

## Usage

```
let BluetoothCP = require("react-native-bluetooth-cross-platform")
```

## Advertise To Become Visible to Other Peers

Advertise takes one argument which can be one of "WIFI", "BT", or "WIFI-BT". Likewise, the WIFI option advertises this device over WI-FI, BT advertises this device over bluetooth, and WIFI-BT advertises this device over both WI-FI and bluetooth channels. \(Default is WIFI-BT\)

**Example: advertise over WIFI**  
BluetoothCP.advertise\("WIFI"\)

## Browse Peers in the Area

Browse takes one argument which can be one of "WIFI", "BT", or "WIFI-BT". Likewise, the WIFI option browses devices over WI-FI, BT browses devices over bluetooth, and WIFI-BT broswes devices over both WI-FI and bluetooth channels. \(Default is WIFI-BT\)

**Example: browse over bluetooth**  
BluetoothCP.advertise\("BT"\)

## Listeners

There are several listeners that can be added to monitor events concerning peers in the area. Add the following callbacks to achieve full functionality. For simplicity, I attempted to mimic Apple's Mutipeer Connectivity API as closely as possible.

##### Subscribing

```
addPeerDetectedListener(callback)
addPeerLostListener(callback)
addReceivedMessageListener(callback)
addInviteListener(callback)
addConnectedListener(callback)

function callback(user) {
    // do stuff
}
```

Each callback takes one argument, and that is a User which contains the following attributes:

```
User {
    id // unique identifier or device id
    type // one of ADVERTISER, BROWSER, OR ADVERTISER_BROWSER
    connected // boolean determining whether or not that user is connected to this user
    display name // the peers display name
}
```

##### Unsubscribing

Simply registering a reference to each listener will allow you to keep track of them and unsubscribe later.

```
componentDidMount() {
    this.listener1 = addPeerDetectedListener(callback)
    this.listener2 = addPeerLostListener(callback)
    this.listener3 = addReceivedMessageListener(callback)
    this.listener4 = addInviteListener(callback)
    this.listener5 = addConnectedListener(callback)
}

componentWillUnmount() {
    this.listener1.remove()
    this.listener2.remove()
    this.listener3.remove()
    this.listener4.remove()
    this.listener5.remove()
}
```

## Actions

Given you know the id of another user which is detected over the callbacks previously listed, you can perform several actions on peers in the area:

```
inviteUser(peerId)
acceptInvitation(peerId)
sendMessage(message, peerId)
disconnectFromPeer(peerId)
```

## Accessing Current State

You may access both peers in the area and those connected to this user through the following callbacks. Both callbacks take an array of users as a single argument.

```
getNearbyPeers(callback)
getConnectedPeers(callback)
```



