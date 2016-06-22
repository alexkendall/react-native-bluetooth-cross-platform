import {
  NativeModules,
  NativeAppEventEmitter,
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
  },
  inviteUser(userId) {
    NativeManager.inviteoUser(userId)
  },
  /*listener callbacks
  user contains .id (required), type(required), connected(required), message(optional),
  */
  addPeerDetectedListener(callback) {
    NativeAppEventEmitter.addListener(
    'detectedUser',
    (user) =>  callback(user)
    );
  },
  // to access message -> message.user
  addReceivedMessageListener(callback) {
    NativeAppEventEmitter.addListener(
      'messageRecieved',
      (user) => callback(user)
    );
  },
  addConnectedListener(callback) {
    NativeAppEventEmitter.addListener(
      'connectedToUser',
      (user) => callback(user)
    );
  }
}
