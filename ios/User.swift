import Foundation
import Underdark

public class User: NSObject {
  var link: UDLink!
  var deviceId: String = ""
  
  override init() {
    super.init()
  }
  
  init(inLink: UDLink, inId: String) {
    link = inLink
    deviceId = inId
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
