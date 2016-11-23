import Foundation

//  REACT METHODS TO BRIDGE -> LEVERAGES BASIC ADVERTISER BROWSER FUNCTIONALITY
protocol ReactNearby {
  func browse(_ kind: String) -> Void
  func stopBrowsing()
  func advertise(_ kind: String) -> Void
  func stopAdvertising()
  func getConnectedPeers(_ callback: RCTResponseSenderBlock)
  func getNearbyPeers(_ callback: RCTResponseSenderBlock)
  func inviteUser(_ id: String)
  func acceptInvitation(_ userId: String)
  func disconnectFromPeer(_ peerId: String)
  func sendMessage(_ message: String, userId:String)
}
