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
  }
  render() {
    return (
      <View style={styles.container}>
        <TouchableOpacity onPress={()=>{
          NetworkManager.sayHello("World")
        }}>
          <View style={styles.scanButton}>
            <Text style={styles.scanText}>SCAN</Text>
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
    justifyContent: "center",
    alignItems: "center",
  },
  scanText: {
    color: "red",
  }
});

AppRegistry.registerComponent('RCTUnderdark', () => RCTUnderdark);
