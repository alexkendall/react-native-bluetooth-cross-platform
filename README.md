# react-native-bluetooth-cross-platform
Cross-Platform React Native Component for Bluetooth &amp; WiFi. Share data over bluetooth between Android and iOS devices.

## Contributions
If you would like to contribute to this repository, please do fork the project and submit a PR.

## Manual Installation(iOS)
1.) npm install --save react-native-bluetooth-cross-platform  

2.) add files in './node_modules/react-native-bluetooth-cross-platform/ios/react-native-bluetooth-cross-platform' to project. When XCode asks to create bridging header, click YES. Delete the bridging header XCode generates for you.

3.) In the project's' Build Settings, set bridging header to '$SRCROOT/../node_modules/react-native-bluetooth-cross-platform/ios/react-native-bluetooth-cross-platform/Bridge.h'

4.) Add 'Underdark' and 'ProtocolBuffers' to Link Binary With Libraries Build Phase

5.) Add a new copy files phase in Build Settings. Set destination to 'Frameworks' and drag 'Underdark' and 'ProtocolBuffers' from the added group to the Copy Files area.

6.) Under Framework Search Paths in the project's' Build Settings, add '$(SRCROOT)/../../react-native-bluetooth-cross-platform/ios/react-native-bluetooth-cross-platform/' and set to recursive.

## Manual Installation(Android)
1.) npm install --save react-native-bluetooth-cross-platform

2.) Under settings.gradle, add the following:
```
include ':react-native-bluetooth-cross-platform'
project(':react-native-bluetooth-cross-platform').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-bluetooth-cross-platform/android')
```

3.) Under your project level build.gradle under repositories add the underdark dependency
```
    repositories {
		...
        maven {
            url 'https://dl.bintray.com/underdark/android/'
        }
    }
```

4.) Under your app level build.gradle, add the following: 
```
dependencies {
    ...
    compile project(':react-native-bluetooth-cross-platform')
}
```

5.) Under MainApplication.java add the following import to the top of the file:
```
import com.rctunderdark.NetworkManagerPackage;
```
and under getPackages add the NetworkManagerPackage:
```
protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),..., new NetworkManagerPackage()
      );
    }
```

# Usage
```
let BluetoothCP = require("react-native-bluetooth-cross-platform")
```
## Advertise To Become Visible to Other Peers
Advertise takes one argument which can be one of "WIFI", "BT", or "WIFI-BT". Likewise, the WIFI option advertises this device over WI-FI, BT advertises this device over bluetooth, and WIFI-BT advertises this device over both WI-FI and bluetooth channels. (Default is WIFI-BT)

**Example: advertise over WIFI**
BluetoothCP.advertise("WIFI")

## Browse Peers in the Area
Browse takes one argument which can be one of "WIFI", "BT", or "WIFI-BT". Likewise, the WIFI option browses devices over WI-FI, BT browses devices over bluetooth, and WIFI-BT broswes devices over both WI-FI and bluetooth channels. (Default is WIFI-BT)

**Example: browse over bluetooth**
BluetoothCP.advertise("BT")

## Listeners
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
