import Foundation
import Underdark

@objc(NetworkManager)
class NetworkManager: NSObject, UDTransportDelegate {
  private var transport: UDTransport? = nil
  private var links: [UDLink] = [UDLink]()
  private let deviceId: String = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
  private var connectedUsers: [User] = [User]()
  private var advertiseTimer: NSTimer! = nil
  private var type: User.PeerType = User.PeerType.OFFLINE
  // MARK: Private Functions
  private func initTransport(kind: String) {
    if transport != nil {
      return
    }
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
    transport?.start()
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
    print("broadcasting type...\(dataStr ?? "")")
    for i in 0..<links.count {
      links[i].sendFrame(data)
    }
  }
  func stopTransort() {
    transport?.stop()
    transport = nil
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
    transport?.stop()
    transport = nil
    if self.type == .ADVERTISER_BROWSER {
      self.type = .ADVERTISER
      return
    }
    self.type = .OFFLINE
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
    print("should stop advertising...")
    transport?.stop()
    transport = nil
    if self.type == .ADVERTISER_BROWSER {
      self.type = .BROWSER
      return
    }
    self.type = .OFFLINE
  }
  
  // MARK: Network Manager Transport Delegate
  @objc func transport(transport: UDTransport!, linkConnected link: UDLink!) {
   print("link connected")
    links.append(link)
  }
  
  @objc func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
    print("link disconnected")
    for i in 0..<links.count {
      if link.nodeId == links[i].nodeId {
        links.removeAtIndex(i)
      }
    }
  }
  @objc func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
    let strData = String(data: frameData, encoding: NSUTF8StringEncoding)!
    print("did recieve frame \(strData)")
  }
}
