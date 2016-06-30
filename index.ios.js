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
  ActionSheetIOS,
  Dimensions,
  TextInput,
} from 'react-native';
var NetworkManager = require('./NetworkManager.js')
var User = require('./User.js')

class RCTUnderdark extends Component {
  constructor(props) {
    var ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    let mpcSrc = {renderType: "mpc", advertising: false, browsing: false,}
    let textSrc = {renderType: "textInput"}
    let source = [textSrc, mpcSrc];
    super(props)
    this.state = {
      browsing: false,
      advertising: false,
      ds: ds.cloneWithRows(source),
      users: [],
      text: "",
    }
    this.toggleAdvertise = this.toggleAdvertise.bind(this)
    this.toggleBrowse = this.toggleBrowse.bind(this)
    this.getButtonStyle = this.getButtonStyle.bind(this)
    this.detectedUser = this.detectedUser.bind(this)
    this.lostUser = this.lostUser.bind(this)
    this.renderUser = this.renderUser.bind(this)
    this.renderMPC = this.renderMPC.bind(this)
    this.updateDS = this.updateDS.bind(this)
    this.renderRow = this.renderRow.bind(this)
    this.connectedToUser = this.connectedToUser.bind(this)
    this.receievedMessage = this.receievedMessage.bind(this)
  }
  updateDS() {
    NetworkManager.getNearbyPeers((peers) => {
      let mpcSrc = {renderType: "mpc", advertising: this.state.advertising, browsing: this.state.browsing,}
      let textSrc = {renderType: "textInput"}
      let source = [textSrc, mpcSrc];
      for(var i = 0; i < peers.length; ++i) {
        let user = new User(peers[i])
        source.push(user)
      }
      this.setState({
        users: peers,
        ds: this.state.ds.cloneWithRows(source)
      })
    })
  }
  componentDidMount() {
    // eventListeners
    NetworkManager.addPeerDetectedListener(this.detectedUser)
    NetworkManager.addInviteListener(this.handleInvite)
    NetworkManager.addConnectedListener(this.connectedToUser)
    NetworkManager.addPeerLostListener(this.lostUser)
    NetworkManager.addReceivedMessageListener(this.receievedMessage)
  }
  receievedMessage(message){
    console.log(message)
  }
  detectedUser(dict) {
    this.updateDS()
  }
  connectedToUser(user) {
    this.updateDS()
  }
  lostUser(user) {
    this.updateDS()
  }
  handleInvite(user) {
    var buttons = [
      'Accept',
      'Cancel',
    ];
    ActionSheetIOS.showActionSheetWithOptions({
      options: buttons,
      cancelButtonIndex: 1,
      destructiveButtonIndex: 0,
    },
    (buttonIndex) => {
      if(buttonIndex == 0) {
        NetworkManager.acceptInvitation(user.id)
        return
      }
    });
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
    this.updateDS()
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
    this.updateDS()
  }
  renderUser(user) {
    let mainColor = user.connected ? "blue" : "black"
    return (
      <TouchableOpacity onPress={() => {
          NetworkManager.inviteUser(user.id)
        }}>
      <View style={{marginBottom: 15,}}>
        <Text style={{fontSize: 14, fontWeight: "800", color: mainColor}}> Id: {user.id} </Text>
        <Text> PeerType: {user.type} </Text>
        <Text> Connected: {user.connected.toString()} </Text>
        <Text> Message: {user.message} </Text>
      </View>
      </TouchableOpacity>
    )
  }
  renderMPC(model) {
    return (
    <View style={{flexDirection: "row", justifyContent: "space-around", flex: 1,}}>
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
    )
  }
  renderTextInput() {
    return (
      <View style={{flexDirection: "row",}}>
        <TextInput
          style={{height: 40, borderColor: 'gray', borderWidth: 1, marginBottom: 10, flex: 1,}}
          onChangeText={(text)=> {
            this.setState({
              text: text,
            })
          }}
          />
        <TouchableOpacity onPress={()=> {
          NetworkManager.getNearbyPeers((peers)=> {
            for(var i = 0; i < peers.length; ++i) {
              NetworkManager.sendMessage(this.state.text, peers[i].id)
            }
            })
          }}>
          <View style={{height: 40, width: 40, backgroundColor: "#000000",}}>
          </View>
        </TouchableOpacity>
      </View>
    )
  }
  renderRow(model){
    if(model.renderType == "user") {
      return this.renderUser(model)
    } else if(model.renderType == "mpc") {
      return this.renderMPC(model)
    }
    return this.renderTextInput();
  }
  render() {
    return (
      <View style={styles.container}>
        <ListView
        dataSource={this.state.ds}
        renderRow={this.renderRow}
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
});

AppRegistry.registerComponent('RCTUnderdark', () => RCTUnderdark);
