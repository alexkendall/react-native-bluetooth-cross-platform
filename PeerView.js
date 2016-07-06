import React, {Component} from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image
} from 'react-native';
import SwipeableViews from 'react-swipeable-views/lib/index.native.animated';
var NetworkManager = require('./NetworkManager.js')

class PeerView extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      page: "default",
      user: props.user,
    }
  }
  render() {
    let wifiSource = this.state.user.connected ? require('./images/wifi_connected.png') : require('./images/wifi_disconnected.png')
    return (
      <SwipeableViews>
      <TouchableOpacity onPress={() => {
          NetworkManager.inviteUser(this.state.user.id)
        }}>
      <View style={{marginBottom: 15, marginLeft: 15, marginRight: 15,}}>
        <View style={{flexDirection: "row", justifyContent: "center", alignItems: "center"}}>
          <Image style={{height: 50, width: 50,}} source={require('./images/person.png')}/>
          <Text style={{fontSize: 14, fontWeight: "700", flex: 1, color: "black"}}>{this.state.user.id} </Text>
          <Image style={{height: 50, width: 50, marginLeft: 10,}} source={wifiSource}/>
        </View>
        <View style={{flexDirection: "row", justifyContent: "center", alignItems: "center"}}>
          <Text style={{flex: 1,}}> PeerType: {this.state.user.type} </Text>
          <Text style={{flex: 1,}}> Connected: {this.state.user.connected.toString()} </Text>
        </View>
      </View>
      </TouchableOpacity>
      <View style={styles.delete}><Text style={{color: "white", fontSize: 20}}>DISCONNECT</Text></View>
      </SwipeableViews>
    )
  }
}

const styles = StyleSheet.create({
  delete: {
    backgroundColor: "#EE0000",
    height: 100,
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  default: {
    backgroundColor: "blue",
    height: 100,
    flex: 1,
  }
})

module.exports = PeerView
