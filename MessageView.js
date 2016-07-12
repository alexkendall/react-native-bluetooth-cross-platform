import React, {Component} from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image,
} from 'react-native';
import SwipeableViews from 'react-swipeable-views/lib/index.native.animated';

class MessageView extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      page: "default",
      message: props.model.message,
      userId: props.model.userId,
      tag: props.model.tag,
    }
  }
  render() {
    return (
      <SwipeableViews>
      <View style={styles.default}>
        <Image source={require('./images/user.png')} style={styles.avatar}></Image>
        <Text style={styles.messageText}>{this.state.message}</Text>
      </View>
      <TouchableOpacity onPress={()=> {
        this.props.removeMessage(this.state.tag)
      }}>
        <View style={styles.delete}><Text style={{color: "white", fontSize: 20}}>Delete</Text></View>
        </TouchableOpacity>
      </SwipeableViews>
    )
  }
}

const styles = StyleSheet.create({
  delete: {
    backgroundColor: "#536DFE",
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    height: 65.0,
  },
  default: {
    alignItems: "center",
    justifyContent: "center",
    flexDirection: "row",
    backgroundColor: "white",
    height: 65.0,
  },
  avatar: {
    height: 40,
    width: 40,
    marginRight: 10,
  },
  messageText: {
    flex: 1,
    marginRight: 10,
  },
})

module.exports = MessageView
