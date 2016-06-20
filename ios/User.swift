import Foundation
import Underdark

public class User: NSObject {
  var nodeId: Int64 = 0
  var deviceId: String = ""
  public enum PeerType {
    case BROWSER
    case ADVERTISER
    case ADVERTISER_BROWSER
    case OFFLINE
  }
}
