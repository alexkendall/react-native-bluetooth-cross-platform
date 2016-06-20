import Foundation

public protocol NetworkManagerDelegate {
  func detectedUser(user: User)
  func recievedInvitationFromUser(user: User, invitationHandler: (accept: Bool)-> Void)
  func connectedToUser(user: User)
  func recievedMessageFromUser(message: String, user: User)
}