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
var NetworkManager = NativeModules.NetworkManager

class RCTUnderdark extends Component {
  constructor(props) {
    super(props)
    this.observe = this.observe.bind(this)
  }
  render() {
    return (
      <View style={styles.container}>
        <TouchableOpacity onPress={()=>{
          NetworkManager.observe("WIFI")
        }}>
          <View style={styles.scanButton}>
            <Text style={styles.scanText}>WIFI</Text>
          </View>
        </TouchableOpacity>
        <TouchableOpacity onPress={()=>{
          NetworkManager.observe("BT")
        }}>
          <View style={styles.scanButton}>
            <Text style={styles.scanText}>BLUETOOTH</Text>
          </View>
        </TouchableOpacity>
        <TouchableOpacity onPress={()=>{
          NetworkManager.observe("WIFI-BT")
        }}>
          <View style={styles.scanButton}>
            <Text style={styles.scanText}>WIFI & BLUETOOTH</Text>
          </View>
        </TouchableOpacity>
      </View>
    );
  }
  observe(type) {
    if (type == "WIFI") {
      NetworkManager.initTransport("WIFI")
    } else if (type == "BT") {
      NetworkManager.initTransport("BT")
    } else if (type == "WIFI-BT") {
      NetworkManager.initTransport("WIFI-BT")
    }
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
