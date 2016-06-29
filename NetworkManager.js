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
    NativeManager.inviteUser(userId)
  },
  acceptInvitation(userId) {
    NativeManager.acceptInvitation(userId)
  },
  getNearbyPeers(callback) {
    NativeManager.getNearbyPeers((peers) => {
      callback(peers)
    })
  },
  getConnectedPeers(callback) {
    NativeManager.getConnectedPeers((peers) => {
      callback(peers)
    })
  },
  /*listener callbacks
  user contains .id (string), type(string), connected(bool), message(string),
  */
  addPeerDetectedListener(callback) {
    NativeAppEventEmitter.addListener(
    'detectedUser',
    (user) =>  callback(user)
    );
  },
  addPeerLostListener(callback) {
    NativeAppEventEmitter.addListener(
    'lostUser',
    (user) => callback(user)
    );
  },
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
  },
  addInviteListener(callback) {
    NativeAppEventEmitter.addListener(
      'receivedInvitation',
      (user) => callback(user)
    );
  },
  addConnectedListener(callback) {
    NativeAppEventEmitter.addListener(
      'connectedToUser',
      (user) => callback(user)
    );
  },
}
