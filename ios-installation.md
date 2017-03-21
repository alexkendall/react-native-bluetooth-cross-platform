# iOS Installation

1.\) `npm install --save react-native-bluetooth-cross-platform`

2.\) add files in `'./node_modules/react-native-bluetooth-cross-platform/ios/react-native-bluetooth-cross-platform'` to project. When XCode asks to create bridging header, click YES. Delete the bridging header XCode generates for you.

3.\) In your project's Build Settings, set bridging header to `$SRCROOT/../node_modules/react-native-bluetooth-cross-platform/ios/react-native-bluetooth-cross-platform/Bridge.h`  
![Imgur](http://i.imgur.com/h2DohGp.png)

4.\) Add 'Underdark' and 'ProtocolBuffers' to Link Binary With Libraries Build Phase  
![Imgur](http://i.imgur.com/VgiOG2F.png)

5.\) Add a new copy files phase in Build Phases. Set destination to 'Frameworks' and drag 'Underdark' and 'ProtocolBuffers' from the added group to the Copy Files area.  
![Imgur](http://i.imgur.com/hRDFFrX.png)  
![Imgur](http://i.imgur.com/Eu4wA0s.png)

6.\) Under Framework Search Paths in the project's' Build Settings, add '$\(SRCROOT\)/../node\_modules/react-native-bluetooth-cross-platform/ios/react-native-bluetooth-cross-platform/' and set to recursive.  
![Imgur](http://i.imgur.com/gTmAojX.png)

