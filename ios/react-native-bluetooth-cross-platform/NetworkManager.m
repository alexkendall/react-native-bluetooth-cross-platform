#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>


@interface RCT_EXTERN_MODULE(NetworkManager, NSObject)

RCT_EXTERN_METHOD(browse:(NSString*)kind)

RCT_EXTERN_METHOD(advertise:(NSString*)kind)

RCT_EXTERN_METHOD(stopAdvertising)

RCT_EXTERN_METHOD(stopBrowsing)

RCT_EXTERN_METHOD(inviteUser:(NSString*)userId)

RCT_EXTERN_METHOD(acceptInvitation:(NSString*)userId)

RCT_EXTERN_METHOD(getConnectedPeers:(RCTResponseSenderBlock)callback)

RCT_EXTERN_METHOD(getNearbyPeers:(RCTResponseSenderBlock)callback)

RCT_EXTERN_METHOD(sendMessage:(NSString*)message userId:(NSString*)userId)

RCT_EXTERN_METHOD(disconnectFromPeer:(NSString*)peerId);

@end
