//
//  UDLink.h
//  Underdark
//
//  Created by Virl on 01/07/15.
//  Copyright (c) 2015 Underdark. All rights reserved.
//

#ifndef Underdark_UDLink_h
#define Underdark_UDLink_h

#import "UDSource.h"
#import "UDFuture.h"

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
 * Begins long transfer.
 * Specifically, disables Bluetooth discovery and advertisement
 * for the duration of the transfer to speed it up.
 * Each call to this method must be balanced by call to [longTransferEnd].
 * If link disconnects, you don't need to call this method
 * — all previous calls to [longTransferBegin] are balanced automatically.
 * * @see longTransferEnd
 */
- (void) longTransferBegin;

/**
 * Finishes long transfer.
 * Specifically, enables back Bluetooth discovery and advertisement.
 * Each call to this method must correspond to
 * previously called [longTransferBegin].
 * If link disconnects, you don't need to call this method
 * — all previous calls to [longTransferBegin] are balanced automatically.
 * @see longTransferBegin
 */
- (void) longTransferEnd;

/**
 * Sends bytes to remote device as single atomic frame.
 * @param frameData bytes to send.
 */
- (nonnull UDFuture*) sendFrame:(nonnull NSData*)frameData;

/**
 * Sends bytes to remote device as single atomic frame.
 * @param dataSource data source with bytes to send.
 */
- (nonnull UDFuture*) sendFrameWithSource:(nonnull UDSource*)source;

@end


#endif
