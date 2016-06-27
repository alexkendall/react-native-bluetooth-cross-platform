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
    this.state = {
      browsing: false,
      advertising: false,
    }
    this.toggleAdvertise = this.toggleAdvertise.bind(this)
    this.toggleBrowse = this.toggleBrowse.bind(this)
    this.getButtonStyle = this.getButtonStyle.bind(this)
  }
  toggleBrowse() {
    if(this.state.browsing) {
      NetworkManager.stopBrowsing()
    } else {
      NetworkManager.browse("WIFI-BT")
    }
    this.setState({
      browsing: !this.state.browsing
    })
  }

  toggleAdvertise() {
    if(this.state.advertising) {
      NetworkManager.stopAdvertising()
    } else {
      NetworkManager.advertise("WIFI-BT")
    }
    this.setState({
      advertising: !this.state.advertising
    })
  }
  render() {
    return (
      <View style={styles.container}>
        <TouchableOpacity onPress={()=>{
          this.toggleAdvertise()
        }}>
          <View style={this.getButtonStyle(this.state.advertising)}>
            <Text style={styles.scanText}>ADVERTISE</Text>
          </View>
        </TouchableOpacity>
        <TouchableOpacity onPress={()=>{
          this.toggleBrowse()
        }}>
          <View style={this.getButtonStyle(this.state.browsing)}>
            <Text style={styles.scanText}>BROWSE</Text>
          </View>
        </TouchableOpacity>
      </View>
    );
  }
  getButtonStyle(on) {
    if(on) {
      return {
        backgroundColor: "black",
        height: 35,
        width: 100,
        marginBottom: 20,
        justifyContent: "center",
        alignItems: "center",
      }
    } else {
      return {
        backgroundColor: "gray",
        height: 35,
        width: 100,
        marginBottom: 20,
        justifyContent: "center",
        alignItems: "center",
      }
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
  onButton: {
    backgroundColor: "black",
    height: 35,
    width: 100,
    marginBottom: 20,
    justifyContent: "center",
    alignItems: "center",
  },
  offButton: {
    backgroundColor: "gray",
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
