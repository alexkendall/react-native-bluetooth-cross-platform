import Foundation
import UIKit
import Underdark

@objc (NetworkCommunicator)
public class NetworkCommunicator: TransportHandler, MessageEncoder, MessageDecoder {
  
  // delimiters
  private var displayDelimeter: String = "$%#";
  private var typeDelimeter: String = "%$#";
  private var deviceDelimeter: String = "$#%";
  private var advertiseTimer: Timer? = nil
  private let deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
  private let displayName: String = UIDevice.current.name
  private var type: User.PeerType = User.PeerType.OFFLINE
  
  override open func initTransport(_ kind: String, inType: User.PeerType) {
    super.initTransport(kind, inType: inType)
    self.type = inType
    initTimer()
  }
  func initTimer() {
    DispatchQueue.main.async(execute: {
      if self.advertiseTimer == nil {
        self.advertiseTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.broadcastType), userInfo: nil, repeats: true)
        RunLoop.main.add(self.advertiseTimer!, forMode: RunLoopMode.defaultRunLoopMode)
      }
    })
  }
  
  open override func stopTransport() {
    if advertiseTimer != nil {
      advertiseTimer?.invalidate()
      advertiseTimer = nil
    }
  }
  
  // HANDLE RECIEVING NEW FRAME
  override open func transport(_ transport: UDTransport, link: UDLink, didReceiveFrame frameData: Data) {
    super.transport(transport, link: link, didReceiveFrame: frameData);
    let message = getMessage(frameData: frameData) ?? ""
    let name = getDisplayName(frameData: frameData) ?? ""
    let id = getDeviceId(frameData: frameData) ?? ""
    var user: User? = nil
    
    switch message {
    case "advertiserbrowser":
      user = User(inLink: link, inId: id, inConnected: false, peerType: .ADVERTISER_BROWSER, name: name)
      checkForNewUsers(user!)
      return
    case "advertiser":
      user = User(inLink: link, inId: id, inConnected: false, peerType: .ADVERTISER, name: name)
      checkForNewUsers(user!)
      return
    case "browser":
      user = User(inLink: link, inId: id, inConnected: false, peerType: .BROWSER, name: name)
      checkForNewUsers(user!)
      return
    case "invitation":
      user = findUser(id)
      if user != nil {
        self.sendEvent(withName: "receivedInvitation", body: user!.getJSUser("invitation"))
      }
      return
    case "accepted":
      user = findUser(id)
      if user != nil {
        user!.connected = true
        informConnected(user: user!)
        self.sendEvent(withName: "connectedToUser", body: user!.getJSUser("connected"))
      }
      return
    case "connected":
      user = findUser(id)
      if user != nil {
        user?.connected = true
        self.sendEvent(withName: "connectedToUser", body: user?.getJSUser("connected"))
      }
      return
    case "disconnected":
      user = findUser(id)
      if user != nil {
        user?.connected = false
        self.sendEvent(withName: "lostUser", body: user!.getJSUser("lost peer"))
      }
      break
    default:
      user = findUser(id)
      if user != nil {
        self.sendEvent(withName: "messageReceived", body: user?.getJSUser(message))
      }
      return
    }
  }
  
  // MARK: MESSAGE ENCODER PROTOCOOL
  open func sendMessage(message: String, userId:String) {
    if let user = findUser(userId) {
      let data = "\(displayName)\(displayDelimeter)\(self.type.rawValue)\(typeDelimeter)\(deviceId)\(deviceDelimeter)\(message)".data(using: String.Encoding.utf8)
      user.link.sendFrame(data!)
    }
  }
  open func sendMessage(message: String, link:UDLink) {
    let data = "\(displayName)\(displayDelimeter)\(self.type.rawValue)\(typeDelimeter)\(deviceId)\(deviceDelimeter)\(message)".data(using: String.Encoding.utf8)
    link.sendFrame(data!)
  }
  open func informConnected(user: User) {
    self.sendMessage(message: "connected", link: user.link)
  }
  open func informDisonnected(user: User) {
    sendMessage(message: "disconnected", link: user.link)
    user.connected = false
    self.sendEvent(withName: "lostUser", body: user.getJSUser("lost peer"))
    
  }
  open func informAcceptedInvite(user: User) {
    sendMessage(message: "accepted", link: user.link)
  }
  open func inviteUser(user: User) {
    sendMessage(message: "invitation", link: user.link)
  }
  open func broadcastType() {
    for i in 0..<links.count {
      sendMessage(message: self.type.rawValue, link: links[i])
    }
  }
  // MARK: MESSAGE DECODER PROTOCOOL
  open func getDisplayName(frameData: Data)-> String? {
    let str: String = String(data: frameData, encoding: String.Encoding.utf8) ?? ""
    if let endIndex: Int = str.getIndexOf(displayDelimeter) {
      let displayName = str.substring(with: str.startIndex..<str.characters.index(str.startIndex, offsetBy: endIndex))
      return displayName
    }
    return nil
  }
  open func getType(frameData: Data)-> String? {
    let str: String = String(data: frameData, encoding: String.Encoding.utf8) ?? ""
    if let startIndex: Int = str.getIndexOf(displayDelimeter) {
      if let endIndex: Int = str.getIndexOf(typeDelimeter) {
        return str.substring(with: str.characters.index(str.startIndex, offsetBy: startIndex)..<str.characters.index(str.startIndex, offsetBy: endIndex))
      }
    }
    return nil
  }
  open func getDeviceId(frameData: Data)-> String? {
    let str: String = String(data: frameData, encoding: String.Encoding.utf8) ?? ""
    if let startIndex: Int = str.getIndexOf(typeDelimeter) {
      if let endIndex: Int = str.getIndexOf(deviceDelimeter) {
        let deviceId = str.substring(with: str.characters.index(str.startIndex, offsetBy: startIndex)..<str.characters.index(str.startIndex, offsetBy: endIndex))
        return deviceId
      }
    }
    return nil
  }
  open func getMessage(frameData: Data)-> String? {
    let str: String = String(data: frameData, encoding: String.Encoding.utf8) ?? ""
    if let startIndex: Int = str.getIndexOf(deviceDelimeter) {
      let start = str.index(str.startIndex, offsetBy: startIndex + deviceDelimeter.characters.count)
      let message = str.substring(with: start..<str.endIndex)
      return message
    }
    return nil
  }
  
  // MARK: Utility functions
  open func findUser(_ id: String) -> User? {
    for user in nearbyUsers {
      if user.deviceId == id {
        return user
      }
    }
    return nil
  }
  fileprivate func checkForNewUsers(_ user: User) {
    for i in 0..<nearbyUsers.count {
      if nearbyUsers[i].deviceId == user.deviceId && nearbyUsers[i].mode != user.mode {
        nearbyUsers[i].mode = user.mode;
        return;
      }
      return;
    }
    nearbyUsers.append(user)
    self.sendEvent(withName: "detectedUser", body: user.getJSUser("new user"))
  }
  
  override open func supportedEvents() -> [String]! {
    return ["lostUser","detectedUser", "messageReceived", "connectedToUser", "receivedInvitation"]
  }
}
