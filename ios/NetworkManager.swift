import Foundation
import Underdark

@objc(NetworkManager)
open class NetworkManager: NSObject, ReactNearby {
  fileprivate var type: User.PeerType = User.PeerType.OFFLINE

  //  MARK: REACT NEARBY UTILITY PROTOCOOL
  @objc open func advertise(_ kind: String) -> Void {
    if self.type == .BROWSER {
      self.type = .ADVERTISER_BROWSER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .ADVERTISER_BROWSER)
    } else if self.type == .OFFLINE {
      self.type = .ADVERTISER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .ADVERTISER)
    }
  }
  
  @objc open func stopAdvertising() {
    if self.type == .ADVERTISER_BROWSER {
      self.type = .BROWSER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .BROWSER)
      return
    }
    self.type = .OFFLINE
    NetworkCommunicator.sharedInstance.stopTransport()
  }
  @objc open func browse(_ kind: String) -> Void {
    if self.type == .ADVERTISER {
      self.type = .ADVERTISER_BROWSER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .ADVERTISER_BROWSER)
    } else if self.type == .OFFLINE {
      self.type = .BROWSER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .BROWSER)
    }
  }
  
  @objc open func stopBrowsing() {
    if self.type == .ADVERTISER_BROWSER {
      self.type = .ADVERTISER
      NetworkCommunicator.sharedInstance.initTransport("WIFI-BT", inType: .ADVERTISER)
      return
    }
    self.type = .OFFLINE
    NetworkCommunicator.sharedInstance.stopTransport()
  }
  @objc open func getConnectedPeers(_ callback: RCTResponseSenderBlock) {
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
  @objc open func getNearbyPeers(_ callback: RCTResponseSenderBlock) {
    var jsUsers = [[String: AnyObject]]()
    let nearbyUsers = NetworkCommunicator.sharedInstance.nearbyUsers
    for user in nearbyUsers {
      jsUsers.append(user.getJSUser(nil))
    }
    callback([jsUsers])
  }
  @objc open func inviteUser(_ id: String) {
    let user = NetworkCommunicator.sharedInstance.findUser(id)
    if(user != nil) {
      user!.connected = true
      NetworkCommunicator.sharedInstance.inviteUser(user: user!)
    }
  }
  @objc open func acceptInvitation(_ userId: String) {
    let user = NetworkCommunicator.sharedInstance.findUser(userId)
    if(user != nil) {
      user!.connected = true
      NetworkCommunicator.sharedInstance.informAcceptedInvite(user: user!)
    }
  }
  @objc open func disconnectFromPeer(_ peerId: String) {
    let user = NetworkCommunicator.sharedInstance.findUser(peerId)
    if(user != nil) {
      user!.connected = false
      NetworkCommunicator.sharedInstance.informDisonnected(user: user!)
    }
  }
  @objc open func sendMessage(_ message: String, userId:String) {
    NetworkCommunicator.sharedInstance.sendMessage(message: message, userId: userId)
  }
}
