//
//  UDLink.h
//  Underdark
//
//  Created by Virl on 01/07/15.
//  Copyright (c) 2015 Underdark. All rights reserved.
//

#ifndef Underdark_UDLink_h
#define Underdark_UDLink_h

/**
 * Class for the connection objects with discovered remote devices.
 * All methods and properties of this class must be accessed
 * only on the delegate queue of corresponding UDTransport.
 */
@protocol UDLink <NSObject>

/**
 * nodeId of remote device
 */
@property (nonatomic, readonly) int64_t nodeId;

@property (nonatomic, readonly) int16_t priority;	// Lower value means higher priority (like unix nice).

@property (nonatomic, readonly) bool slowLink;

/**
 * Disconnects remote device after all pending output frame have been sent to it.
 */
- (void) disconnect;

/**
 * Sends bytes to remote device as single atomic frame.
 * @param frameData bytes to send.
 */
- (void) sendFrame:(NSData*)frameData;

@end


#endif
