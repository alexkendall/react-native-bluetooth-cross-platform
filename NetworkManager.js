import {
  NativeModules,
} from 'react-native';
import React from 'react';

var NativeManager = NativeModules.NetworkManager

module.exports = {
  browse(kind) {
    NativeManager.browse(kind)
  },
  advertise(kind) {
    NativeManager.advertise(kind)
  }
}
