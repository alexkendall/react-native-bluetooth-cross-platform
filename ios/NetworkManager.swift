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
        }
        return
      }
    }
    var id = ""
    if strData.containsString("browseradvertiser_") {
      id = strData.stringByReplacingOccurrencesOfString("browseradvertiser_", withString: "")
    } else if strData.containsString("advertiser_") {
      id = strData.stringByReplacingOccurrencesOfString("advertiser_", withString: "")
    } else if strData.containsString("browser_") {
      id = strData.stringByReplacingOccurrencesOfString("browser_", withString: "")
    }
    let user = User(inLink: link, inId: id, inConnected: false)
    nearbyUsers.append(user)
    delegate?.detectedUser(user)
    self.log()
  }
}
