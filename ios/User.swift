import Foundation
import Underdark

public class User: NSObject {
  var link: UDLink!
  var deviceId: String = ""
  var connected: Bool = false
  
  override init() {
    super.init()
  }
  
  init(inLink: UDLink, inId: String, inConnected: Bool) {
    link = inLink
    deviceId = inId
    connected = inConnected
  }
  public enum PeerType {
    case BROWSER
    case ADVERTISER
    case ADVERTISER_BROWSER
    case OFFLINE
  }
  
  func logInfo() {
    print("Link \(link)\nDeviceID: \(deviceId)")
  }
}
