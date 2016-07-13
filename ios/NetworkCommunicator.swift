import Foundation

public class NetworkCommunicator: TransportHandler, MessageEncoder, MessageDecoder {
  
  // delimiters
  private var displayDelimeter: String = "$%#";
  private var typeDelimeter: String = "%$#";
  private var deviceDelimeter: String = "$#%";
  private var advertiseTimer: NSTimer? = nil
  private let deviceId: String = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
  private let displayName: String = UIDevice.currentDevice().name
  private var type: User.PeerType = User.PeerType.OFFLINE
  static let sharedInstance = NetworkCommunicator()
  
  override public func initTransport(kind: String, inType: User.PeerType) {
    super.initTransport(kind, inType: inType)
    self.type = inType
    initTimer()
  }
  func initTimer() {
    dispatch_async(dispatch_get_main_queue(), {
      if self.advertiseTimer == nil {
        self.advertiseTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(self.broadcastType), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.advertiseTimer!, forMode: NSDefaultRunLoopMode)
      }
    })
  }
  
  public override func stopTransport() {
    if advertiseTimer != nil {
      advertiseTimer?.invalidate()
      advertiseTimer = nil
    }
  }
  
  // HANDLE RECIEVING NEW FRAME
  override public func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
    super.transport(transport, link: link, didReceiveFrame: frameData);
    let message = getMessage(frameData) ?? ""
    let name = getDisplayName(frameData) ?? ""
    let id = getDeviceId(frameData) ?? ""
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
  
  // MARK: MESSAGE ENCODER PROTOCOOL
  public func sendMessage(message: String, userId:String) {
    if let user = findUser(userId) {
      let data = "\(displayName)\(displayDelimeter)\(self.type.rawValue)\(typeDelimeter)\(deviceId)\(deviceDelimeter)\(message)".dataUsingEncoding(NSUTF8StringEncoding)
      user.link.sendFrame(data)
    }
  }
  public func sendMessage(message: String, link:UDLink) {
    let data = "\(displayName)\(displayDelimeter)\(self.type.rawValue)\(typeDelimeter)\(deviceId)\(deviceDelimeter)\(message)".dataUsingEncoding(NSUTF8StringEncoding)
    link.sendFrame(data)
  }
  public func informConnected(user: User) {
    sendMessage("connected", link: user.link)
  }
  public func informDisonnected(user: User) {
    sendMessage("disconnected", link: user.link)
    user.connected = false
    bridge.eventDispatcher().sendAppEventWithName("lostUser", body: user.getJSUser("lost peer"))
    
  }
  public func informAcceptedInvite(user: User) {
    sendMessage("accepted", link: user.link)
  }
  public func inviteUser(user: User) {
    sendMessage("invitation", link: user.link)
  }
  public func broadcastType() {
    for i in 0..<links.count {
      sendMessage(self.type.rawValue, link: links[i])
      }
    }
  // MARK: MESSAGE DECODER PROTOCOOL
  public func getDisplayName(frameData: NSData)-> String? {
    let str: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if let endIndex: Int = str.getIndexOf(displayDelimeter) {
      let displayName = str.substringWithRange(str.startIndex..<str.startIndex.advancedBy(endIndex))
      return displayName
    }
    return nil
  }
  public func getType(frameData: NSData)-> String? {
    let str: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if let startIndex: Int = str.getIndexOf(displayDelimeter) {
      if let endIndex: Int = str.getIndexOf(typeDelimeter) {
        return str.substringWithRange(str.startIndex.advancedBy(startIndex)..<str.startIndex.advancedBy(endIndex))
      }
    }
    return nil
  }
  public func getDeviceId(frameData: NSData)-> String? {
    let str: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if let startIndex: Int = str.getIndexOf(typeDelimeter) {
      if let endIndex: Int = str.getIndexOf(deviceDelimeter) {
        let deviceId = str.substringWithRange(str.startIndex.advancedBy(startIndex).advancedBy(typeDelimeter.characters.count)..<str.startIndex.advancedBy(endIndex))
        return deviceId
      }
    }
    return nil
  }
  public func getMessage(frameData: NSData)-> String? {
    let str: String = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
    if let startIndex: Int = str.getIndexOf(deviceDelimeter) {
      let message = str.substringWithRange(str.startIndex.advancedBy(startIndex).advancedBy(deviceDelimeter.characters.count)..<str.endIndex)
      return message
    }
    return nil
  }
  
  // MARK: Utility functions
  public func findUser(id: String) -> User? {
    for user in nearbyUsers {
      if user.deviceId == id {
        return user
      }
    }
    return nil
  }
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
}
