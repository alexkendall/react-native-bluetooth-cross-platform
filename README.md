# RCTUnderdark
Cross-Platform React Native Component for Bluetooth &amp; WiFi. Share data over bluetooth between Android and iOS devices.

# Manual Installation
1. Download as zip file and unzip.
2. Drag project folder to node-modules
3. Import project to libraries and copy static library into build Phases

# Usage
****Import
```
import BluetoothCP from "react-native-bluetooth-cross-platform"
```
****Advertise
Advertise takes one argument which can be one of "WIFI", "BT", or "WIFI-BT". Likewise, the WIFI option advertises this device over WI-FI, BT advertises this device over bluetooth, and WIFI-BT advertises this device over both WI-FI and bluetooth channels. (Default is WIFI-BT)

**Example: advertise over WIFI**
BluetoothCP.advertise("WIFI")

****Browse
Browse takes one argument which can be one of "WIFI", "BT", or "WIFI-BT". Likewise, the WIFI option browses devices over WI-FI, BT browses devices over bluetooth, and WIFI-BT broswes devices over both WI-FI and bluetooth channels. (Default is WIFI-BT)

**Example: browse over bluetooth**
BluetoothCP.advertise("BT")

****Listeners
There are several listeners that can be added to monitor events concerning peers in the area. Add the following callbacks to achieve full functionality. For simplicity, I attempted to mimic Apple's Mutipeer Connectivity API as closely as possible.
```
addPeerDetectedListener(callback)
addPeerLostListener(callback)
addReceivedMessageListener(callback)
addInviteListener(callback);
addConnectedListener(callback);
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
****Actions
Given you know the id of another user which is detected over the callbacks previously listed, you can perform several actions on peers in the area:
```
inviteUser(peerId)
acceptInvitation(peerId)
sendMessage(message, peerId)
disconnectFromPeer(peerId)
 ```
****Accessing Current State
You may access both peers in the area and those connected to this user through the following callbacks. Both callbacks take an array of users as a single argument.
```
getNearbyPeers(callback)
getConnectedPeers(callback)
```


```
