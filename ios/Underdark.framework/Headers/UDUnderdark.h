//
//  UDUnderdark.h
//  Solidarity
//
//  Created by Virl on 29/06/15.
//  Copyright (c) 2015 Glint. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UDLogger.h"
#import "UDTransport.h"

typedef NS_ENUM(NSUInteger, UDTransportKind) {
	UDTransportKindWifi			= (1 << 0),
	UDTransportKindBluetooth	= (1 << 1)
};

/**
 * Entry point for Underdark framework.
 * Methods of this class allow you to configure transport object
 * for communitcation with apps on other devices.
 */
@interface UDUnderdark : NSObject

+ (id<UDLogger>) logger;
+ (void) setLogger:(id<UDLogger>)logger;

/**
 * Configures aggregate UDTransport that supports communication through given protocols.
 * It must be started via [UDTransport start] before use
 * and stopped via [UDTransport stop] when is no longer needed.
 * @param appId identifier for current application. Must be same across all devices.
 * @param nodeId globally unique identifier of curent device.
 * @param delegate delegate for transport events.
 * @param queue queue which will be used to dispatch delegate callbacks.
 *                Supply nil if you want to receive callbacks on main thread.
 * @param kinds 0 or more NSNumber values of UDTransportKind
 *                       for communication protocols.
 * @return transport that communicates via specified protocols and uses given delegate for callbacks.
 * All methods of returned UDTransport object must be called on supplied queue.
 */
+ (id<UDTransport>) configureTransportWithAppId:(int32_t)appId
										 nodeId:(int64_t)nodeId
									   delegate:(id<UDTransportDelegate>)delegate
										  queue:(dispatch_queue_t)queue
										  kinds:(NSArray*)kinds;

@end
