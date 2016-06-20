import {
  NativeModules,
} from 'react-native';
import React from 'react';

var NativeManager = NativeModules.NetworkManager
module.exports = {
  // kind can be one of "WIFI", "BT", and "WIFI-BT"
  browse(kind) {
    NativeManager.browse(kind)
  },
  // kind can be one of "WIFI", "BT", and "WIFI-BT"
  advertise(kind) {
    NativeManager.advertise(kind)
  },
  stopAdvertising() {
    NativeManager.stopAdvertising()
  },
  stopBrowsing() {
    NativeManager.stopBrowsing()
  }
}
