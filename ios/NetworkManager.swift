import Foundation
import Underdark

@objc(NetworkManager)
public class NetworkManager: NSObject, ReactNearby {
  private var type: User.PeerType = User.PeerType.OFFLINE

  //  MARK: REACT NEARBY UTILITY PROTOCOOL
  @objc public func advertise(kind: String) -> Void {
    if self.type == .BROWSER {
      self.type = .ADVERTISER_BROWSER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .ADVERTISER_BROWSER)
    } else if self.type == .OFFLINE {
      self.type = .ADVERTISER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .ADVERTISER)
    }
  }
  
  @objc public func stopAdvertising() {
    if self.type == .ADVERTISER_BROWSER {
      self.type = .BROWSER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .BROWSER)
      return
    }
    self.type = .OFFLINE
    NetworkCommunicator.sharedInstance.stopTransport()
  }
  @objc public func browse(kind: String) -> Void {
    if self.type == .ADVERTISER {
      self.type = .ADVERTISER_BROWSER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .ADVERTISER_BROWSER)
    } else if self.type == .OFFLINE {
      self.type = .BROWSER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .BROWSER)
    }
  }
  
  @objc public func stopBrowsing() {
    if self.type == .ADVERTISER_BROWSER {
      self.type = .ADVERTISER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .ADVERTISER)
      return
    }
    self.type = .OFFLINE
    NetworkCommunicator.sharedInstance.stopTransport()
  }
  @objc public func getConnectedPeers(callback: RCTResponseSenderBlock) {
    var connectedPeers = [[String: AnyObject]]()
    let nearbyUsers = NetworkCommunicator.sharedInstance.nearbyUsers
    if self.type == .BROWSER || self.type == .ADVERTISER_BROWSER {
      for user in nearbyUsers {
        if user.connected {
          connectedPeers.append(user.getJSUser(nil))
        }
      }
    }
    callback([connectedPeers])
  }
  @objc public func getNearbyPeers(callback: RCTResponseSenderBlock) {
    var jsUsers = [[String: AnyObject]]()
    let nearbyUsers = NetworkCommunicator.sharedInstance.nearbyUsers
    for user in nearbyUsers {
      jsUsers.append(user.getJSUser(nil))
    }
    callback([jsUsers])
  }
  @objc public func inviteUser(id: String) {
    let user = NetworkCommunicator.sharedInstance.findUser(id)
    if(user != nil) {
      user!.connected = true
      NetworkCommunicator.sharedInstance.inviteUser(user!)
    }
  }
  @objc public func acceptInvitation(userId: String) {
    let user = NetworkCommunicator.sharedInstance.findUser(userId)
    if(user != nil) {
      user!.connected = true
      NetworkCommunicator.sharedInstance.informAcceptedInvite(user!)
    }
  }
  @objc public func disconnectFromPeer(peerId: String) {
    let user = NetworkCommunicator.sharedInstance.findUser(peerId)
    if(user != nil) {
      user!.connected = true
      NetworkCommunicator.sharedInstance.informDisonnected(user!)
    }
  }
  @objc public func sendMessage(message: String, userId:String) {
    NetworkCommunicator.sharedInstance.sendMessage(message, userId: userId)
  }
}
