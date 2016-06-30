import Foundation
import Underdark

@objc(NetworkManager)
public class NetworkManager: NSObject, UDTransportDelegate {
  private var transport: UDTransport? = nil
  private let deviceId: String = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
  private var links: [UDLink] = [UDLink]()
  private var nearbyUsers: [User] = [User]()
  private var advertiseTimer: NSTimer! = nil
  private var type: User.PeerType = User.PeerType.OFFLINE
  private var transportConfigured: Bool = false
  public var delegate: NetworkManagerDelegate? = nil
  private var nodeId: Int64 = 0;
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
    var dataStr: String?
    var data: NSData?
      switch self.type {
      case .OFFLINE:
        dataStr = "offline_\(self.deviceId)"
        break
      case .ADVERTISER:
        dataStr = "advertiser_\(self.deviceId)"
        break
      case .BROWSER:
        dataStr = "browser_\(self.deviceId)"
        break
      case .ADVERTISER_BROWSER:
        dataStr = "advertiserbrowser_\(self.deviceId)"
        break
    }
    data = dataStr?.dataUsingEncoding(NSUTF8StringEncoding)
    for i in 0..<links.count {
      links[i].sendFrame(data)
    }
  }
  func stopTransort() {
    transport?.stop()
    advertiseTimer.invalidate()
    advertiseTimer = nil
  }
  func getJSUser(user: User, message: String?) -> [String: AnyObject] {
    var obj = [String: AnyObject]()
    obj["connected"] = user.connected
    obj["id"] = user.deviceId
    obj["message"] = message ?? ""
    obj["type"] = user.mode.rawValue
    return obj
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
          let obj = getJSUser(connectedUser, message: nil)
          connectedPeers.append(obj)
        }
      }
    }
    callback([connectedPeers])
  }
  @objc func getNearbyPeers(callback: RCTResponseSenderBlock) {
    var jsUsers = [[String: AnyObject]]()
    for     i in 0..<self.nearbyUsers.count {
      jsUsers.append(getJSUser(nearbyUsers[i], message: nil))
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
  @objc func messageUser(message: String, id: String) {
    let msgData = "message_\(deviceId)".dataUsingEncoding(NSUTF8StringEncoding)
    let user = findUser(id)
    if user != nil {
      user?.link.sendFrame(msgData)
    }
  }
  @objc func inviteUser(id: String) {
    let msgStr = "invitation_\(deviceId)"
    for i in 0..<nearbyUsers.count {
      if nearbyUsers[i].deviceId == id {
        nearbyUsers[i].link.sendFrame(msgStr.dataUsingEncoding(NSUTF8StringEncoding))
      }
    }
  }
  @objc func acceptInvitation(userId: String) {
    let msg = "accepted_\(deviceId)".dataUsingEncoding(NSUTF8StringEncoding)
    for i in 0..<nearbyUsers.count {
      if nearbyUsers[i].deviceId == userId {
        nearbyUsers[i].connected = true
        nearbyUsers[i].link.sendFrame(msg)
      }
    }
    let user = findUser(userId)
    if(user != nil) {
      informAcceptedInvite(user!)
    }
  }
  @objc func sendMessage(message: String, userId:String) {
    if let user = findUser(userId) {
      let data = "\(message)_\(deviceId)".dataUsingEncoding(NSUTF8StringEncoding)
      user.link.sendFrame(data)
    }
  }
  // MARK: Network Manager Transport Delegate
  @objc public func transport(transport: UDTransport!, linkConnected link: UDLink!) {
    links.append(link)
  }
  
  @objc public func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
    for i in 0..<links.count {
      if link.nodeId == links[i].nodeId {
        links.removeAtIndex(i)
        break
      }
    }
    for i in 0..<nearbyUsers.count {
      if nearbyUsers[i].link.nodeId == link.nodeId {
        nearbyUsers.removeAtIndex(i)
        return
      }
    }
  }
  @objc public func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
    if(link.nodeId == self.nodeId) {
      return;
    }
    var user: User? = nil
    let message: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if containsKeyword(message) {
      let keyword: String = getKeywordFromMessage(message)
      let id: String = getDeviceID(message)
      switch keyword {
      case "advertiserbrowser_":
        user = User(inLink: link, inId: id, inConnected: false, peerType: .ADVERTISER_BROWSER)
        checkForNewUsers(user!)
        return
      case "advertiser_":
        user = User(inLink: link, inId: id, inConnected: false, peerType: .ADVERTISER)
        checkForNewUsers(user!)
        return
      case "browser_":
        user = User(inLink: link, inId: id, inConnected: false, peerType: .BROWSER)
        checkForNewUsers(user!)
        return
      case "invitation_":
        user = findUser(id)
        if user != nil {
          bridge.eventDispatcher().sendAppEventWithName("receivedInvitation", body: getJSUser(user!, message: "invitation"))
        }
        return
      case "accepted_":
        user = findUser(id)
        if user != nil {
          user!.connected = true
          informConnected(user!)
          bridge.eventDispatcher().sendAppEventWithName("connectedToUser", body: getJSUser(user!, message: "connected"))
        }
        return
      case "connected_":
        user = findUser(id)
        if user != nil {
          user?.connected = true
          bridge.eventDispatcher().sendAppEventWithName("connectedToUser", body: getJSUser(user!, message: "connected"))
        }
        return
      default:
        return
      }
    } else {
      let parsedMessage = getUnformattedMessage(message)
      bridge.eventDispatcher().sendAppEventWithName("messageRecieved", body: parsedMessage)
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
    let jsUser = getJSUser(user, message: "newUser");
    bridge.eventDispatcher().sendAppEventWithName("detectedUser", body: jsUser)
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
  private func getDeviceID(message: String) -> String {
    var parsedMessage = message
    let keywords: [String] = ["advertiserbrowser", "advertiser_", "browser_", "invitation_", "accepted_", "connected_"]
    for key in keywords {
      parsedMessage = parsedMessage.stringByReplacingOccurrencesOfString(key, withString: "")
    }
    return parsedMessage
  }
  
  private func getKeywordFromMessage(message: String) -> String {
    let deviceID = getDeviceID(message)
    return message.stringByReplacingOccurrencesOfString(deviceID, withString: "")
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
    for user in nearbyUsers {
      if user.deviceId == id {
        return user
      }
    }
    return nil
  }
  private func informConnected(user: User) {
    let data = "connected_\(deviceId)".dataUsingEncoding(NSUTF8StringEncoding)
    user.link.sendFrame(data)
    
  }
  private func informAcceptedInvite(user: User) {
    let data = "accepted_\(deviceId)".dataUsingEncoding(NSUTF8StringEncoding)
    user.link.sendFrame(data)
    
  }
}
