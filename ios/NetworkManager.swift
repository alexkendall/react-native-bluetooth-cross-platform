import Foundation
import Underdark

@objc(NetworkManager)
public class NetworkManager: NSObject, UDTransportDelegate {
  private var transport: UDTransport? = nil
  private let deviceId: String = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
  private let displayName: String = UIDevice.currentDevice().name
  private var links: [UDLink] = [UDLink]()
  private var nearbyUsers: [User] = [User]()
  private var advertiseTimer: NSTimer! = nil
  private var type: User.PeerType = User.PeerType.OFFLINE
  private var transportConfigured: Bool = false
  public var delegate: NetworkManagerDelegate? = nil
  private var nodeId: Int64 = 0;
  
  // delimiters
  private var displayDelimeter: String = "$%#";
  private var typeDelimeter: String = "%$#";
  private var deviceDelimeter: String = "$#%";

  // MARK: Private Functions
  private func initTransport(kind: String) {
    if !self.transportConfigured {
      let appId: Int32 = 234235
      let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
      var buf : Int64 = 0;
      while buf == 0 {
        arc4random_buf(&buf, sizeofValue(buf))
      }
      if buf < 0 {
        buf = -buf
      }
      nodeId = buf
      var transportKinds = [AnyObject]()
      if kind == "WIFI" {
        transportKinds.append(UDTransportKind.Wifi.rawValue)
      }
      if kind == "BT" {
        transportKinds.append(UDTransportKind.Bluetooth.rawValue)
      }
      if kind == "WIFI-BT" {
        transportKinds.append(UDTransportKind.Bluetooth.rawValue)
        transportKinds.append(UDTransportKind.Wifi.rawValue)
      }
      transport = UDUnderdark.configureTransportWithAppId(appId, nodeId: nodeId, delegate: self, queue: queue, kinds: transportKinds)
      self.transportConfigured = true
    }
    transport?.start()
  }
  func log() {
    for i in 0..<nearbyUsers.count {
      nearbyUsers[i].logInfo()
    }
  }
  func initTimer() {
    dispatch_async(dispatch_get_main_queue(), {
      if self.advertiseTimer == nil {
        self.advertiseTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(self.broadcastType), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.advertiseTimer, forMode: NSDefaultRunLoopMode)
      }
    })
  }
  func broadcastType() {
    for i in 0..<links.count {
      sendMessage(self.type.rawValue, link: links[i])
    }
  }
  func stopTransort() {
    transport?.stop()
    advertiseTimer.invalidate()
    advertiseTimer = nil
  }
  //  MARK: Underdark Browser
  @objc func browse(kind: String) -> Void {
    if self.type == .ADVERTISER {
      self.type = .ADVERTISER_BROWSER
    } else if self.type == .OFFLINE {
      self.type = .BROWSER
    }
    self.initTransport(kind)
    self.initTimer()
  }
  
  @objc func stopBrowsing() {
    if self.type == .ADVERTISER_BROWSER {
      self.type = .ADVERTISER
      return
    }
    self.type = .OFFLINE
    stopTransort()
  }
  @objc func getConnectedPeers(callback: RCTResponseSenderBlock) {
    var connectedPeers = [[String: AnyObject]]()
    if self.type == .BROWSER || self.type == .ADVERTISER_BROWSER {
      for i in 0..<nearbyUsers.count {
        if nearbyUsers[i].connected {
          let connectedUser = nearbyUsers[i]
          connectedPeers.append(connectedUser.getJSUser(nil))
        }
      }
    }
    callback([connectedPeers])
  }
  @objc func getNearbyPeers(callback: RCTResponseSenderBlock) {
    var jsUsers = [[String: AnyObject]]()
    for i in 0..<self.nearbyUsers.count {
      jsUsers.append(nearbyUsers[i].getJSUser(nil))
    }
    callback([jsUsers])
  }
  // MARK: Underdark Advertiser
  @objc func advertise(kind: String) -> Void {
    if self.type == .BROWSER {
      self.type = .ADVERTISER_BROWSER
    } else if self.type == .OFFLINE {
      self.type = .ADVERTISER
    }
    self.initTransport(kind)
    self.initTimer()
  }
  
  @objc func stopAdvertising() {
    if self.type == .ADVERTISER_BROWSER {
      self.type = .BROWSER
      return
    }
    self.type = .OFFLINE
    stopTransort()
  }
  // MARK: Communication Implementation
  @objc func inviteUser(id: String) {
    sendMessage("invitation", userId: id)
  }
  @objc func acceptInvitation(userId: String) {
    let user = findUser(userId)
    if(user != nil) {
      user?.connected = true
      informAcceptedInvite(user!)
      sendMessage("accepted", userId: userId)
    }
  }
  @objc public func disconnectFromPeer(peerId: String) {
    let user = findUser(peerId)
    if user != nil {
      sendMessage("disconnected", userId: peerId)
      user?.connected = false
      bridge.eventDispatcher().sendAppEventWithName("lostUser", body: user!.getJSUser("lost peer"))
      }
  }
  // MARK: Network Manager Transport Delegate
  @objc public func transport(transport: UDTransport!, linkConnected link: UDLink!) {
    links.append(link)
  }
  
  @objc public func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
    var i = 0;
    while i < links.count {
      if link.nodeId == links[i].nodeId {
        links.removeAtIndex(i)
      } else {
        i += 1
      }
    }
    i = 0;
    while i < nearbyUsers.count {
      if link.nodeId == nearbyUsers[i].link.nodeId {
        bridge.eventDispatcher().sendAppEventWithName("lostUser", body: nearbyUsers[i].getJSUser("lost peer"))
        nearbyUsers.removeAtIndex(i)
      } else {
        i += 1
      }
    }
  }
  @objc public func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
    if link.nodeId == self.nodeId {
      return
    }
    let id = getDeviceId(frameData) ?? ""
    if id == self.deviceId {
      return
    }
    let message = getMessage(frameData) ?? ""
    let name = getDisplayName(frameData) ?? ""
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
          bridge.eventDispatcher().sendAppEventWithName("receivedInvitation", body: user!.getJSUser("invitation"))
          print("recieved invitation from: \(user!.displayName)")
        }
        return
      case "accepted":
        user = findUser(id)
        if user != nil {
          user!.connected = true
          informConnected(user!)
          bridge.eventDispatcher().sendAppEventWithName("connectedToUser", body: user!.getJSUser("connected"))
        }
        return
      case "connected":
        user = findUser(id)
        if user != nil {
          user?.connected = true
          bridge.eventDispatcher().sendAppEventWithName("connectedToUser", body: user?.getJSUser("connected"))
        }
        return
      case "disconnected":
        user = findUser(id)
        if user != nil {
          user?.connected = false
          bridge.eventDispatcher().sendAppEventWithName("lostUser", body: user!.getJSUser("lost peer"))
        }
        break
      default:
        user = findUser(id)
        if user != nil {
          bridge.eventDispatcher().sendAppEventWithName("messageReceived", body: user?.getJSUser(message))
        }
        return
      }
  }
  // MARK: Swift Helpers
  private func checkForNewUsers(user: User) {
    for i in 0..<nearbyUsers.count {
      if nearbyUsers[i].deviceId == user.deviceId && nearbyUsers[i].mode != user.mode {
        nearbyUsers[i].mode = user.mode;
        return;
      }
      return;
    }
    nearbyUsers.append(user)
    bridge.eventDispatcher().sendAppEventWithName("detectedUser", body: user.getJSUser("new user"))
  }
  private func containsKeyword(message: String) -> Bool {
    let keywords: [String] = ["advertiserbrowser", "advertiser_", "browser_", "invitation_", "accepted_", "connected_"]
    for key in keywords {
      if message.containsString(key) {
        return true
      }
    }
    return false
  }
  private func getUnformattedMessage(message: String) -> String? {
    var i = 0;
    for c in message.characters {
      if c == "_" {
        return message.substringToIndex(message.characters.startIndex.advancedBy(i))
      }
      i = i + 1;
    }
    return nil
  }
  private func findUser(id: String) -> User? {
    print("find user id: \(id)")
    for user in nearbyUsers {
      if user.deviceId == id {
        return user
      }
    }
    return nil
  }
  private func informConnected(user: User) {
    sendMessage("connected", link: user.link)
    
  }
  private func informAcceptedInvite(user: User) {
    sendMessage("accepted", link: user.link)
    
  }
  @objc func sendMessage(message: String, userId:String) {
    if let user = findUser(userId) {
      let data = "\(displayName)\(displayDelimeter)\(self.type.rawValue)\(typeDelimeter)\(deviceId)\(deviceDelimeter)\(message)".dataUsingEncoding(NSUTF8StringEncoding)
      user.link.sendFrame(data)
    }
  }
  @objc func sendMessage(message: String, link:UDLink) {
    let data = "\(displayName)\(displayDelimeter)\(self.type.rawValue)\(typeDelimeter)\(deviceId)\(deviceDelimeter)\(message)".dataUsingEncoding(NSUTF8StringEncoding)
    link.sendFrame(data)
  }
  private func getDisplayName(frameData: NSData)-> String? {
    let str: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if let endIndex: Int = str.getIndexOf(displayDelimeter) {
      let displayName = str.substringWithRange(str.startIndex..<str.startIndex.advancedBy(endIndex))
      return displayName
    }
    return nil
  }
  private func getType(frameData: NSData)-> String? {
    let str: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if let startIndex: Int = str.getIndexOf(displayDelimeter) {
      if let endIndex: Int = str.getIndexOf(typeDelimeter) {
        return str.substringWithRange(str.startIndex.advancedBy(startIndex)..<str.startIndex.advancedBy(endIndex))
      }
    }
    return nil
  }
  private func getDeviceId(frameData: NSData)-> String? {
    let str: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if let startIndex: Int = str.getIndexOf(typeDelimeter) {
      if let endIndex: Int = str.getIndexOf(deviceDelimeter) {
        let deviceId = str.substringWithRange(str.startIndex.advancedBy(startIndex).advancedBy(typeDelimeter.characters.count)..<str.startIndex.advancedBy(endIndex))
        return deviceId
      }
    }
    return nil
  }
  private func getMessage(frameData: NSData)-> String? {
    let str: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if let startIndex: Int = str.getIndexOf(deviceDelimeter) {
      let message = str.substringWithRange(str.startIndex.advancedBy(startIndex).advancedBy(deviceDelimeter.characters.count)..<str.endIndex)
      return message
    }
    return nil
  }
}

