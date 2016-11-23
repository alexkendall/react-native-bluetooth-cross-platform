import Foundation
import Underdark

public protocol MessageEncoder {
  func sendMessage(message: String, userId:String)
  func sendMessage(message: String, link:UDLink)
  func informConnected(user: User)
  func informDisonnected(user: User)
  func informAcceptedInvite(user: User)
  func inviteUser(user: User)
  func broadcastType()
}
