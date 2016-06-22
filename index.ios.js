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
  NativeAppEventEmitter,
  ListView,
} from 'react-native';
var NetworkManager = require('./NetworkManager.js')
var User = require('./User.js')

class RCTUnderdark extends Component {
  constructor(props) {
    var ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    super(props)
    this.state = {
      browsing: false,
      advertising: false,
      ds: ds,
      users: [],
    }
    this.toggleAdvertise = this.toggleAdvertise.bind(this)
    this.toggleBrowse = this.toggleBrowse.bind(this)
    this.getButtonStyle = this.getButtonStyle.bind(this)
    this.detectedUser = this.detectedUser.bind(this)
    this.renderUser = this.renderUser.bind(this)
  }
  componentDidMount() {
    NetworkManager.addPeerDetectedListener(this.detectedUser)
  }
  detectedUser(dict) {
    var newUser = new User(dict)
    var newUsers = this.state.users
    for(var i = 0; i < newUser.count; ++i){
      if (newUser.id == newUsers[i].id) {
        newUsers[i].type = newUser.type
        this.setState({
          ds: this.state.ds.cloneWithRows(newUsers),
          users: newUsers,
        })
        return
      }
    }
    newUsers.push(newUser)
    this.setState({
      ds: this.state.ds.cloneWithRows(newUsers),
      users: newUsers,
    })
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
  renderUser(user) {
    return (
      <View>
      <Text> Id: {user.id} </Text>
      <Text> PeerType: {user.type} </Text>
      <Text> Connected: {user.connected} </Text>
      <Text> Message: {user.message} </Text>
      </View>
    )
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
        <ListView
          style={styles.listView}
          dataSource={this.state.ds}
          renderRow={this.renderUser}
        />
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
    marginTop: 30,
  },
  onButton: {
    backgroundColor: "black",
    height: 35,
    width: 100,
    marginTop: 30,
    justifyContent: "center",
    alignItems: "center",
  },
  offButton: {
    backgroundColor: "gray",
    height: 35,
    width: 100,
    marginTop: 30,
    justifyContent: "center",
    alignItems: "center",
  },
  scanText: {
    color: "white",
    textAlign: "center",
  },
  listView: {
    marginBottom: 50,
  },
});

AppRegistry.registerComponent('RCTUnderdark', () => RCTUnderdark);
