import Foundation
import Underdark

@objc(NetworkManager)
class NetworkManager: NSObject, UDTransportDelegate {
  var transport: UDTransport? = nil
  @objc func sayHello(name: String) -> Void {
    print("Hello World")
  }
  @objc func observe(kind: String) -> Void {
    if transport != nil {
      transport?.stop()
    }
    let appId: Int32 = 234235
    let nodeId: Int64
    let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
    var buf : Int64 = 0;
    while buf == 0 {
      arc4random_buf(&buf, sizeofValue(buf))
    }
    if(buf < 0) {
      buf = -buf
    }
    nodeId = buf
    var transportKinds = [AnyObject]()
    if kind == "WIFI" {
      transportKinds.append(UDTransportKind.Wifi.rawValue)
      print("Scanning over Wifi")
    }
    if kind == "BT" {
      transportKinds.append(UDTransportKind.Bluetooth.rawValue)
      print("Scanning over Bluetooth")
    }
    if kind == "WIFI-BT" {
      transportKinds.append(UDTransportKind.Bluetooth.rawValue)
      transportKinds.append(UDTransportKind.Wifi.rawValue)
      print("Scanning over Bluetooth and Wifi")
    }
    [UDTransportKind.Wifi.rawValue, UDTransportKind.Bluetooth.rawValue];
    transport = UDUnderdark.configureTransportWithAppId(appId, nodeId: nodeId, delegate: self, queue: queue, kinds: transportKinds)
    transport?.start()
  }
  
  
  // MARK: Network Manager Transport Delegate
  @objc func transport(transport: UDTransport!, linkConnected link: UDLink!) {
   print("link connected")
  }
  
  @objc func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
    print("link disconnected")
  }
  
  @objc func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
    print("did recieve frame")
  }
}
