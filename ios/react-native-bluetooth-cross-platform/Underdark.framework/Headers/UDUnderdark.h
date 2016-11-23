/*
 * Copyright (c) 2016 Vladimir L. Shabanov <virlof@gmail.com>
 *
 * Licensed under the Underdark License, Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://underdark.io/LICENSE.txt
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

+ (nullable id<UDLogger>) logger;
+ (void) setLogger:(nullable id<UDLogger>)logger;

/**
 * Configures aggregate UDTransport that supports communication through given protocols.
 * It must be started via [UDTransport start] before use
 * and stopped via [UDTransport stop] when is no longer needed.
 * You must set transport's delegate property before using it.
 * @param appId identifier for current application. Must be same across all devices.
 * @param nodeId globally unique identifier of curent device.
 * @param queue queue which will be used to dispatch delegate callbacks.
 *                Supply nil if you want to receive callbacks on main thread.
 * @param kinds 0 or more NSNumber values of UDTransportKind
 *                       for communication protocols.
 * @return transport that communicates via specified protocols and uses given delegate for callbacks.
 * All methods of returned UDTransport object must be called on supplied queue.
 */
+ (nonnull id<UDTransport>) configureTransportWithAppId:(int32_t)appId
												 nodeId:(int64_t)nodeId
												  queue:(nonnull dispatch_queue_t)queue
												  kinds:(nonnull NSArray*)kinds;
@end
