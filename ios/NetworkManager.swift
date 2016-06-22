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
      dispatch_async(dispatch_get_main_queue(), {
        self.logTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.log), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.logTimer, forMode: NSDefaultRunLoopMode)
      })
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
        dataStr = "browseradvertiser_\(self.deviceId)"
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
  @objc func inviteUser(user: User) {
    var msgStr = "invitation_\(deviceId)"
    if self.type == .BROWSER {
      msgStr = "\(msgStr)browser"
    } else {
      msgStr = "\(msgStr)advertiserbrowser"
    }
    user.link.sendFrame(msgStr.dataUsingEncoding(NSUTF8StringEncoding))
  }
  @objc func autheticateUser(id: String) {
    var msgStr = "accepted_\(deviceId)"
    if self.type == .ADVERTISER {
      msgStr = "\(msgStr)avertiser"
    } else {
      msgStr = "\(msgStr)advertiserbrowser"
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
    for i in 0..<nearbyUsers.count {
      if link.nodeId == nearbyUsers[i].link.nodeId {
        let user = nearbyUsers[i]
        if user.connected {
          delegate?.recievedMessageFromUser(strData, user: user)
          var dict = [String: AnyObject]()
          dict["id"] = user.deviceId
          dict["connected"] = user.connected
          dict["message"]  = strData
          dict["type"] = user.mode.rawValue
          bridge.eventDispatcher().sendAppEventWithName("messageReceived", body: dict)
        }
        return
      }
    }
    var id = ""
    var mode = User.PeerType.OFFLINE
    if strData.containsString("browseradvertiser_") {
      id = strData.stringByReplacingOccurrencesOfString("browseradvertiser_", withString: "")
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
        id = strData.stringByReplacingOccurrencesOfString("advertiserbrowser", withString: "")
      } else {
        mode = User.PeerType.BROWSER
         id = strData.stringByReplacingOccurrencesOfString("browser", withString: "")
      }
      let user = User(inLink: link, inId: id, inConnected: true, peerType: mode)
      delegate?.recievedInvitationFromUser(user, invitationHandler: {accept in
        if accept {
          self.autheticateUser(id)
        }
      })
      nearbyUsers.append(user)
      return
    } else if strData.containsString("accepted_") {
      id = strData.stringByReplacingOccurrencesOfString("accepted_", withString: "")
      if strData.containsString("advertiserbrowser") {
        mode = User.PeerType.ADVERTISER_BROWSER
        id = strData.stringByReplacingOccurrencesOfString("advertiserbrowser", withString: "")
      } else {
        mode = User.PeerType.BROWSER
        id = strData.stringByReplacingOccurrencesOfString("advertiser", withString: "")
      }
      let user = User(inLink: link, inId: id, inConnected: true, peerType: mode)
      nearbyUsers.append(user)
      var dict = [String: AnyObject]()
      dict["id"] = user.deviceId
      dict["connected"] = true
      dict["message"] = nil
      dict["type"] = mode.rawValue
      bridge.eventDispatcher().sendAppEventWithName("connectedToUser", body: dict)
      return
    }
    let user = User(inLink: link, inId: id, inConnected: false, peerType: mode)
    nearbyUsers.append(user)
    // fire delegate
    delegate?.detectedUser(user)
    // notify js
    var dict = [String: AnyObject]()
    dict["id"] = user.deviceId
    dict["connected"] = user.connected
    dict["message"] = nil
    dict["type"] = mode.rawValue
    // Only Advertisers are Detectable to User
    if type == .ADVERTISER || type == .ADVERTISER_BROWSER {
      bridge.eventDispatcher().sendAppEventWithName("detectedUser", body: dict)
    }
    self.log()
  }
}
