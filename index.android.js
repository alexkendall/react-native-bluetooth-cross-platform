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
  Dimensions,
  Alert,
  TextInput,
  Image,
} from 'react-native';
var NetworkManager = require('./NetworkManager.js')
var User = require('./User.js')

class RCTUnderdark extends Component {
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
      users: [],
      text: "",
      messages: [],
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
    this.renderMessage = this.renderMessage.bind(this)
  }
  updateDS() {
    NetworkManager.getNearbyPeers((peers) => {
      let mpcSrc = {renderType: "mpc", advertising: this.state.advertising, browsing: this.state.browsing,}
      let textSrc = {renderType: "textInput"}
      let msgHeaderSrc = {renderType: "messageHeader"}
      let mainHeaderSrc = {renderType: "mainHeader"}
      let source = [mainHeaderSrc, textSrc, mpcSrc];
      for(var i = 0; i < peers.length; ++i) {
        let user = new User(peers[i])
        source.push(user)
      }
      source.push(msgHeaderSrc)
      for(var i = 0; i < this.state.messages.length; ++i) {
        let messageModel = {
          message: this.state.messages[i],
          renderType: "message",
        }
        source.push(messageModel)
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
    var messages = this.state.messages
    messages.push(message)
    this.setState({
      messages: messages,
    })
    this.updateDS()
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
    Alert.alert(
      'Invite',
      'User would like to connect',
      [
        {text: 'Accept Connection', onPress: () => NetworkManager.acceptInvitation(user.id)},
        {text: 'Cancel', onPress: () => console.log('Cancel Pressed'), style: 'cancel'},
      ]
    )
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
    let mainColor = user.connected ? "#0099ff" : "black"
    return (
      <TouchableOpacity onPress={() => {
          NetworkManager.inviteUser(user.id)
        }}>
      <View style={{marginBottom: 15, marginRight: 15, marginLeft: 15,}}>
        <View style={{flexDirection: "row", justifyContent: "center", alignItems: "center"}}>
          <Image style={{height: 50, width: 50,}} source={require('./images/person.png')}/>
          <Text style={{fontSize: 14, fontWeight: "800", flex: 1, color: mainColor}}> Id: {user.id} </Text>
        </View>
        <View style={{flexDirection: "row", justifyContent: "center", alignItems: "center"}}>
          <Text style={{flex: 1,}}> PeerType: {user.type} </Text>
          <Text style={{flex: 1,}}> Connected: {user.connected.toString()} </Text>
        </View>
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
        <View style={{flex: 1, height: 30,}}>
          <Text style={{height: 30, color: "white", flex: 1, alignSelf: "center", justifyContent: "center"}}>Inbox</Text>
        </View>
        <View>
          <TouchableOpacity onPress={()=>{
            this.clearInbox()
          }}>
            <Image source={require('./images/delete.png')} style={{height: 25, width: 25,}}/>
          </TouchableOpacity>
        </View>
      </View>
    )
  }
  renderTextInput() {
    return (
      <View style={{flexDirection: "row", marginRight: 15, marginLeft: 15,}}>
          <TextInput
            style={{backgroundColor: "#cccccc", paddingLeft: 10, height: 40, flex: 1, borderColor: 'gray', backgroundColor: "white", borderWidth: 1, borderRadius: 5, marginBottom: 20, marginTop: 5, marginRight: 10, marginLeft: 10,}}
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
          <View style={{height: 40, width: 50, borderRadius: 5, backgroundColor: "#000000", justifyContent: "center", alignItems: "center",marginTop: 5}}>
          <Image style={{height: 30, width: 30,}} source={require('./images/send.png')}/>
          </View>
        </TouchableOpacity>
      </View>
    )
  }
  renderMessage(model) {
    return (
      <View style={{flexDirection: "row", marginTop: 20, marginRight: 15, marginLeft: 15,}}>
        <Image style={{height: 40, width: 40, marginRight: 10}} source={require('./images/user.png')}/>
        <Text style={{fontSize: 16, flex: 1, marginRight: 15,}}>{model.message.message}</Text>
      </View>
    )
  }
  renderRow(model){
    if(model.renderType == "user") {
      return this.renderUser(model)
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

AppRegistry.registerComponent('RCTUnderdark', () => RCTUnderdark);
