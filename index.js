import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  NativeModules,
  NativeAppEventEmitter,
  ListView,
  Dimensions,
  Alert,
  TextInput,
  Image,
  Platform,
  ActionSheetIOS,
} from 'react-native';
var NetworkManager = require('./NetworkManager.js')
var PeerModel = require('./PeerModel.js')
var PeerView = require('./PeerView.js')
var MessageModel = require('./MessageModel.js')
var MessageView = require('./MessageView.js')

class Underdark extends Component {
  constructor(props) {
    var ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    let mpcSrc = {renderType: "mpc", advertising: false, browsing: false,}
    let textSrc = {renderType: "textInput"}
    let msgHeaderSrc = {renderType: "messageHeader"}
    let mainHeaderSrc = {renderType: "mainHeader"}
    let source = [mainHeaderSrc, textSrc, mpcSrc, msgHeaderSrc];
    super(props)
    this.state = {
      browsing: false,
      advertising: false,
      ds: ds.cloneWithRows(source),
      peers: [],
      text: "",
      messages: [],
    }
    this.toggleAdvertise = this.toggleAdvertise.bind(this)
    this.toggleBrowse = this.toggleBrowse.bind(this)
    this.getButtonStyle = this.getButtonStyle.bind(this)
    this.detectedPeer = this.detectedPeer.bind(this)
    this.lostPeer = this.lostPeer.bind(this)
    this.renderPeer = this.renderPeer.bind(this)
    this.renderMPC = this.renderMPC.bind(this)
    this.updateDS = this.updateDS.bind(this)
    this.renderRow = this.renderRow.bind(this)
    this.connectedToPeer = this.connectedToPeer.bind(this)
    this.receievedMessage = this.receievedMessage.bind(this)
    this.renderMessage = this.renderMessage.bind(this)
    this.removeMessage = this.removeMessage.bind(this)
  }
  updateDS() {
    NetworkManager.getNearbyPeers((peers) => {
      let mpcSrc = {renderType: "mpc", advertising: this.state.advertising, browsing: this.state.browsing,}
      let textSrc = {renderType: "textInput"}
      let msgHeaderSrc = {renderType: "messageHeader"}
      let mainHeaderSrc = {renderType: "mainHeader"}
      let source = [mainHeaderSrc, textSrc, mpcSrc];
      for(var i = 0; i < peers.length; ++i) {
        let peerModel = new PeerModel(peers[i])
        source.push(peerModel)
      }
      source.push(msgHeaderSrc)
      for(var i = 0; i < this.state.messages.length; ++i) {
        source.push(this.state.messages[i])
      }
      this.setState({
        peers: peers,
        ds: this.state.ds.cloneWithRows(source)
      })
    })
  }
  componentDidMount() {
    // eventListeners
    NetworkManager.addPeerDetectedListener(this.detectedPeer)
    NetworkManager.addInviteListener(this.handleInvite)
    NetworkManager.addConnectedListener(this.connectedToPeer)
    NetworkManager.addPeerLostListener(this.lostPeer)
    NetworkManager.addReceivedMessageListener(this.receievedMessage)
  }
  receievedMessage(message) {
    var messages = this.state.messages
    messages.push(new MessageModel(message, this.state.messages.length))
    this.setState({
      messages: messages,
    })
    this.updateDS()
  }
  // event listeners
  detectedPeer(dict) {
    console.log("detected peer")
    this.updateDS()
  }
  connectedToPeer(peer) {
    console.log(peer)
    this.updateDS()
  }
  lostPeer(peer) {
    this.updateDS()
  }
  handleInvite(peer) {
    if(Platform.OS == "android") {
      Alert.alert(
        'Invite',
        peer.name + ' would like to connect',
        [
          {text: 'Accept Connection', onPress: () => NetworkManager.acceptInvitation(peer.id)},
          {text: 'Cancel', onPress: () => console.log('Cancel Pressed'), style: 'cancel'},
        ]
      )
      return
    }
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
        NetworkManager.acceptInvitation(peer.id)
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
  renderPeer(peer) {
    return <PeerView peer={peer}/>
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
  renderMainHeader() {
    return (
      <View style={{backgroundColor: "black", height: 60, marginBottom: 15, alignItems: "center", justifyContent: "center"}}>
        <Text style={{color: "white"}}>RCT Underdark</Text>
      </View>
    )
  }
  renderMessageHeader() {
    return (
      <View style={{backgroundColor: "black", height: 30, alignItems: "center", justifyContent: "center", flexDirection: "row"}}>
        <View style={{flex: 1, height: 30, marginRight: -30, alignItems: "center", justifyContent: "center",}}>
          <Text style={{color: "white"}}>Messages</Text>
        </View>
        <TouchableOpacity onPress={()=>{
          this.clearInbox()
        }}>
          <View style={{height: 30, width: 30, alignSelf: "flex-end"}}><Image source={require('./images/delete.png')} style={{height: 25, width: 25,}}/></View>
        </TouchableOpacity>
      </View>
    )
  }
  renderTextInput() {
    return (
      <View style={{flexDirection: "row", marginRight: 15, marginLeft: 15,}}>
          <View style={{marginTop: 5, marginRight: 10, marginBottom: 15, borderRadius: 5, flex: 1, borderWidth: 1, borderColor: "gray", backgroundColor: "white"}}>
          <TextInput
            style={{backgroundColor: "#cccccc", height: 40, flex: 1, borderColor: 'gray', backgroundColor: "white", marginRight: 10, marginLeft: 10,}}
            onChangeText={(text)=> {
              this.setState({
                text: text,
              })
            }}
          />
          </View>
        <TouchableOpacity onPress={()=> {
          NetworkManager.getNearbyPeers((peers)=> {
            for(var i = 0; i < peers.length; ++i) {
              NetworkManager.sendMessage(this.state.text, peers[i].id)
            }
            })
          }}>
          <View style={{height: 40, width: 50, borderRadius: 5, backgroundColor: "#000000", justifyContent: "center", alignItems: "center",marginTop: 5}}>
          <Image style={{height: 30, width: 30,}} source={require('./images/send.png')}/>
          </View>
        </TouchableOpacity>
      </View>
    )
  }
  renderMessage(model) {
    return (
      <MessageView model={model} removeMessage={this.removeMessage}/>
    )
    this.updateDS()
  }
  renderRow(model){
    if(model.renderType == "peer") {
      return this.renderPeer(model)
    } else if(model.renderType == "mpc") {
      return this.renderMPC(model)
    } else if(model.renderType == "message") {
      return this.renderMessage(model)
    } else if(model.renderType == "messageHeader") {
      return this.renderMessageHeader(model)
    } else if(model.renderType == "mainHeader") {
      return this.renderMainHeader(model)
    }
    return this.renderTextInput();
  }
  render() {
    return (
        <ListView
          dataSource={this.state.ds}
          renderRow={this.renderRow}
          contentContainerStyle={{marginBottom: 20,}}
        />
    );
  }
  clearInbox() {
    this.setState({
      messages: [],
    })
    this.updateDS()
  }
  removeMessage(tag) {
    let messages = this.state.messages.splice(tag, 1)
    console.log(messages)
    this.setState({
      messages: messages,
    })
    this.updateDS()
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
  topContainer: {
    height: 50,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#00aaff",
  },
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 30,
    flexDirection: 'column',
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

module.exports = Underdark
