import Foundation

public class TransportHandler: NSObject, UDTransportDelegate {
  
  // delimiterse
  private var type: User.PeerType = User.PeerType.OFFLINE
  private var transportConfigured: Bool = false
  private var transport: UDTransport? = nil
  private var advertiseTimer: NSTimer? = nil
  private var nodeId: Int64 = 0
  internal var links = [UDLink]()
  internal var nearbyUsers = [User]()
  
  // MARK: START TRANSPORT
  public func initTransport(kind: String, inType: User.PeerType) {
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
  // MARK: stop transport
  public func stopTransport() {
    transport?.stop()
  }
  
  // MARK: TRansport delegate
  public func transport(transport: UDTransport!, linkConnected link: UDLink!) {
    links.append(link)
  }
  
  public func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
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
  public func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
    // handle this in network communicatorwith proper encoder and decoder functionality
  }
  
}
