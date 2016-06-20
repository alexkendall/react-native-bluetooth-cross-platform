/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  NativeModules,
} from 'react-native';
var NetworkManager = require('./NetworkManager.js')

class RCTUnderdark extends Component {
  constructor(props) {
    super(props)
    console.log(NetworkManager)
  }
  render() {
    return (
      <View style={styles.container}>
        <TouchableOpacity onPress={()=>{
          NetworkManager.browse("WIFI-BT")
        }}>
          <View style={styles.scanButton}>
            <Text style={styles.scanText}>ADVERTISE</Text>
          </View>
        </TouchableOpacity>
        <TouchableOpacity onPress={()=>{
          NetworkManager.advertise("WIFI-BT")
        }}>
          <View style={styles.scanButton}>
            <Text style={styles.scanText}>BROWSE</Text>
          </View>
        </TouchableOpacity>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5F5F5',
  },
  scanButton: {
    backgroundColor: "black",
    height: 35,
    width: 100,
    marginBottom: 20,
    justifyContent: "center",
    alignItems: "center",
  },
  scanText: {
    color: "white",
    textAlign: "center",
  }
});

AppRegistry.registerComponent('RCTUnderdark', () => RCTUnderdark);
