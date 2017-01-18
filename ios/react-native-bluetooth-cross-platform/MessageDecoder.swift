import Foundation

public protocol MessageDecoder {
  func getDisplayName(frameData: Data)-> String?
  func getType(frameData: Data)-> String?
  func getDeviceId(frameData: Data)-> String?
  func getMessage(frameData: Data)-> String?
}
