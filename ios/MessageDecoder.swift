import Foundation

public protocol MessageDecoder {
  func getDisplayName(frameData: NSData)-> String?
  func getType(frameData: NSData)-> String?
  func getDeviceId(frameData: NSData)-> String?
  func getMessage(frameData: NSData)-> String?

}