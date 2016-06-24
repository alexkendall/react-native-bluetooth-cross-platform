import Foundation

public protocol NetworkManagerDelegate {
  func detectedUser(user: User)
  func recievedInvitationFromUser(user: User, invitationHandler: (accept: Bool)-> Void)
  func connectedToUser(user: User)
  func recievedMessageFromUser(message: String, user: User)
}

// Note, each time a delegat methode is called, corresponding calls are made in js to react native