import Foundation
import Underdark

public class User: NSObject {
  var link: UDLink!
  var deviceId: String = ""
  var connected: Bool = false
  var mode: PeerType!
  
  override init() {
    super.init()
  }
  
  init(inLink: UDLink, inId: String, inConnected: Bool, peerType: PeerType) {
    link = inLink
    deviceId = inId
    connected = inConnected
    mode = peerType
  }
  public enum PeerType: String {
    case BROWSER = "browser"
    case ADVERTISER = "advertiser"
    case ADVERTISER_BROWSER = "advertiserbrowser"
    case OFFLINE = "offline"
  }
  
  func logInfo() {
    print("Link \(link)\nDeviceID: \(deviceId)")
  }
}
