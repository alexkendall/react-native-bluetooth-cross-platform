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
  disconnectFromPeer(peerId) {
    NativeManager.disconnectFromPeer(peerId)
  },
  inviteUser(peerId) {
    NativeManager.inviteUser(peerId)
  },
  sendMessage(message, peerId) {
    NativeManager.sendMessage(message, peerId)
  },
  acceptInvitation(peerId) {
    NativeManager.acceptInvitation(peerId)
  },
  getNearbyPeers(callback) {
    NativeManager.getNearbyPeers((peers) => {
      callback(peers)
      console.log(peers)
    })
  },
  getConnectedPeers(callback) {
    NativeManager.getConnectedPeers((peers) => {
      callback(peers)
    })
  },
  /*listener callbacks
  peer contains .id (string), type(string), connected(bool), message(string),
  */
  addPeerDetectedListener(callback) {
    NativeAppEventEmitter.addListener(
    'detectedUser',
    (peer) =>  callback(peer)
    );
  },
  addPeerLostListener(callback) {
    NativeAppEventEmitter.addListener(
    'lostUser',
    (peer) => callback(peer)
    );
  },
  addReceivedMessageListener(callback) {
    NativeAppEventEmitter.addListener(
      'messageReceived',
      (peer) => callback(peer)
    );
  },
  addInviteListener(callback) {
    NativeAppEventEmitter.addListener(
      'receivedInvitation',
      (peer) => callback(peer)
    );
  },
  addConnectedListener(callback) {
    NativeAppEventEmitter.addListener(
      'connectedToUser',
      (peer) => callback(peer)
    );
  },
}
