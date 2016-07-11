import Foundation
import Underdark

public class User: NSObject {
  var link: UDLink!
  var deviceId: String = ""
  var connected: Bool = false
  var mode: PeerType!
  var displayName: String = ""
  override init() {
    super.init()
  }
  
  init(inLink: UDLink, inId: String, inConnected: Bool, peerType: PeerType, name: String) {
    link = inLink
    deviceId = inId
    connected = inConnected
    mode = peerType
    displayName = name
  }
  public enum PeerType: String {
    case BROWSER = "browser"
    case ADVERTISER = "advertiser"
    case ADVERTISER_BROWSER = "advertiserbrowser"
    case OFFLINE = "offline"
  }
  func getJSUser(message: String?)->[String: AnyObject] {
    var obj = [String: AnyObject]()
    obj["connected"] = self.connected
    obj["id"] = self.deviceId
    obj["message"] = message ?? ""
    obj["type"] = self.mode.rawValue
    obj["name"] = self.displayName
    return obj
  }
  func logInfo() {
    print("Link \(link)\nDeviceID: \(deviceId)")
  }
}
