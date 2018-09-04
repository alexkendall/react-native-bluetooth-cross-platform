import Foundation
import Underdark

open class TransportHandler: RCTEventEmitter, UDTransportDelegate {
  
  // delimiterse
  private var type: User.PeerType = User.PeerType.OFFLINE
  private var transportConfigured: Bool = false
  private var transport: UDTransport? = nil
  private var advertiseTimer: Timer? = nil
  private var nodeId: Int64 = 0
  internal var links = [UDLink]()
  internal var nearbyUsers = [User]()

  // ratkinson - setting up a dispatch queue to handle "links" and "nearbyUsers"
  // logic syncronously in eventHandlers
  let serialQueue = DispatchQueue(label: "serialQueue")
  
  // MARK: START TRANSPORT
  public func initTransport(_ kind: String, inType: User.PeerType) {
    if !self.transportConfigured {
      let appId: Int32 = 234235
      let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
      var buf : Int64 = 0;
      while buf == 0 {
        arc4random_buf(&buf, MemoryLayout.size(ofValue: buf))
      }
      if buf < 0 {
        buf = -buf
      }
      nodeId = buf
      var transportKinds = [AnyObject]()
      if kind == "WIFI" {
        transportKinds.append(UDTransportKind.wifi.rawValue as AnyObject)
      }
      if kind == "BT" {
        transportKinds.append(UDTransportKind.bluetooth.rawValue as AnyObject)
      }
      if kind == "WIFI-BT" {
        transportKinds.append(UDTransportKind.bluetooth.rawValue as AnyObject)
        transportKinds.append(UDTransportKind.wifi.rawValue as AnyObject)
      }
      transport = UDUnderdark.configureTransport(withAppId: appId, nodeId: nodeId, queue: queue, kinds: transportKinds)
      transport?.delegate = self
      self.transportConfigured = true
    }
    transport?.start()
  }

  // MARK: stop transport
  open func stopTransport() {
    transport?.stop()
  }
  
  // MARK: TRansport delegate
  public func transport(_ transport: UDTransport, linkConnected link: UDLink) {
    serialQueue.sync {
      links.append(link)
    }
  }
  
  public func transport(_ transport: UDTransport, linkDisconnected link: UDLink) {
    serialQueue.sync {
      let linksCount = links.count
      var i = (linksCount - 1);

      while i >= 0 {
        if link.nodeId == links[i].nodeId {
          links.remove(at: i)
        }
        i -= 1
      }

      let nearbyUserCount = nearbyUsers.count
      i = (nearbyUserCount - 1)

      while i >= 0 {
        if link.nodeId == nearbyUsers[i].link.nodeId {
          self.sendEvent(withName: "lostUser", body:  nearbyUsers[i].getJSUser("lost peer"))
          nearbyUsers.remove(at: i)
        }
        i -= 1
      }
    }
  }

  public func transport(_ transport: UDTransport, link: UDLink, didReceiveFrame frameData: Data) {
    // handle this in network communicatorwith proper encoder and decoder functionality
  }
  
  override open func supportedEvents() -> [String]! {
    return ["lostUser","detectedUser", "messageReceived", "connectedToUser", "receivedInvitation"]
  }
  
}
