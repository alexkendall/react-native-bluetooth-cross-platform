#import <Foundation/Foundation.h>
#import "RCTBridgeModule.h"


@interface RCT_EXTERN_MODULE(NetworkManager, NSObject)

RCT_EXTERN_METHOD(browse:(NSString*)kind)

RCT_EXTERN_METHOD(advertise:(NSString*)kind)

RCT_EXTERN_METHOD(stopAdvertising)

RCT_EXTERN_METHOD(stopBrowsing)

RCT_EXTERN_METHOD(inviteUser:(NSString*)userId)

@end