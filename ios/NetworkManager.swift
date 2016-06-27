import Foundation
import Underdark

@objc(NetworkManager)
public class NetworkManager: NSObject, UDTransportDelegate {
  private var transport: UDTransport? = nil
  private let deviceId: String = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
  private var links: [UDLink] = [UDLink]()
  private var nearbyUsers: [User] = [User]()
  private var advertiseTimer: NSTimer! = nil
  private var logTimer: NSTimer! = nil
  private var type: User.PeerType = User.PeerType.OFFLINE
  private var transportConfigured: Bool = false
  public var delegate: NetworkManagerDelegate? = nil
  // MARK: Private Functions
  private func initTransport(kind: String) {
    if !self.transportConfigured {
      let appId: Int32 = 234235
      let nodeId: Int64
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
      /*
      dispatch_async(dispatch_get_main_queue(), {
        self.logTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.log), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.logTimer, forMode: NSDefaultRunLoopMode)
      })
      */
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
  @objc func messageUser(message: String, user: User) {
    let msgData = message.dataUsingEncoding(NSUTF8StringEncoding)
    user.link.sendFrame(msgData)
  }
  @objc func inviteUser(id: String) {
    var msgStr = "invitation_\(deviceId)"
    if self.type == .BROWSER {
      msgStr = "\(msgStr)browser"
    } else {
      msgStr = "\(msgStr)advertiserbrowser"
    }
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
    let strData = String(data: frameData, encoding: NSUTF8StringEncoding)!
    print("Recieved Frame: \(strData)")
    for i in 0..<nearbyUsers.count {
      if link.nodeId == nearbyUsers[i].link.nodeId {
        let user = nearbyUsers[i]
        if user.connected {
          delegate?.recievedMessageFromUser(strData, user: user)
          let jsUser = getJSUser(user, message: strData)
          bridge.eventDispatcher().sendAppEventWithName("messageReceived", body: jsUser)
        }
      }
    }
    var id = ""
    var mode = User.PeerType.OFFLINE
    if strData.containsString("advertiserbrowser_") {
      id = strData.stringByReplacingOccurrencesOfString("advertiserbrowser_", withString: "")
      mode = User.PeerType.ADVERTISER_BROWSER
    } else if strData.containsString("advertiser_") {
      id = strData.stringByReplacingOccurrencesOfString("advertiser_", withString: "")
      mode = User.PeerType.ADVERTISER
    } else if strData.containsString("browser_") {
      id = strData.stringByReplacingOccurrencesOfString("browser_", withString: "")
      mode = User.PeerType.BROWSER
    } else if strData.containsString("invitation_") {
      id = strData.stringByReplacingOccurrencesOfString("invitation_", withString: "")
      if strData.containsString("advertiserbrowser") {
        mode = User.PeerType.ADVERTISER_BROWSER
        id = id.stringByReplacingOccurrencesOfString("advertiserbrowser", withString: "")
      } else {
        mode = User.PeerType.BROWSER
         id = id.stringByReplacingOccurrencesOfString("browser", withString: "")
      }
      let user = User(inLink: link, inId: id, inConnected: true, peerType: mode)
      user.logInfo()
      delegate?.recievedInvitationFromUser(user, invitationHandler: {accept in
        if accept {
          self.acceptInvitation(id)
        }
      })
      let jsUser = getJSUser(user, message: "invite")
      bridge.eventDispatcher().sendAppEventWithName("recievedInvitation", body: jsUser)
      return
    } else if strData.containsString("accepted_") {
      id = strData.stringByReplacingOccurrencesOfString("accepted_", withString: "")
      if strData.containsString("advertiserbrowser") {
        mode = User.PeerType.ADVERTISER_BROWSER
        id = id.stringByReplacingOccurrencesOfString("advertiserbrowser", withString: "")
      } else {
        mode = User.PeerType.BROWSER
        id = id.stringByReplacingOccurrencesOfString("advertiser", withString: "")
      }
      let user = User(inLink: link, inId: id, inConnected: true, peerType: mode)
      let jsUser = getJSUser(user, message: strData)
      bridge.eventDispatcher().sendAppEventWithName("connectedToUser", body: jsUser)
      delegate?.connectedToUser(user)
      for i in 0..<self.nearbyUsers.count {
        let nbUser = self.nearbyUsers[i]
        if nbUser.deviceId == id {
          if nbUser.connected != user.connected {
            nbUser.connected = true
          }
        }
      }
      return
    }
    let user = User(inLink: link, inId: id, inConnected: false, peerType: mode)
    for i in 0..<self.nearbyUsers.count {
      let nbUser = self.nearbyUsers[i]
      if nbUser.deviceId == id {
        if nbUser.mode == mode {
          return
        }
        self.nearbyUsers.removeAtIndex(i)
      }
    }
    self.nearbyUsers.append(user)
    // fire delegate
    delegate?.detectedUser(user)
    // notify js
    let jsUser = getJSUser(user, message: strData)
    // Only Advertisers are Detectable to User
    bridge.eventDispatcher().sendAppEventWithName("detectedUser", body: jsUser)
  }
}
