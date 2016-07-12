import Foundation

//  REACT METHODS TO BRIDGE -> LEVERAGES BASIC ADVERTISER BROWSER FUNCTIONALITY
protocol ReactNearby {
  func browse(kind: String) -> Void
  func stopBrowsing()
  func advertise(kind: String) -> Void
  func stopAdvertising()
  func getConnectedPeers(callback: RCTResponseSenderBlock)
  func getNearbyPeers(callback: RCTResponseSenderBlock)
  func inviteUser(id: String)
  func acceptInvitation(userId: String)
  func disconnectFromPeer(peerId: String)
  func sendMessage(message: String, userId:String)
}