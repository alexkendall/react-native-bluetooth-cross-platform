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

#import "UDUnderdark.h"

#import "UDLogging.h"
#import "UDAggTransport.h"
#import "UDBonjourAdapter.h"
#import "UDNsdAdapter.h"

static id<UDLogger> underdarkLogger = nil;

@interface UDUnderdark()

@end

@implementation UDUnderdark

+ (id<UDLogger>) logger
{
	return underdarkLogger;
}

+ (void) setLogger:(id<UDLogger>)logger
{
	underdarkLogger = logger;
}

+ (id<UDTransport>) configureTransportWithAppId:(int32_t)appId
										 nodeId:(int64_t)nodeId
										  queue:(dispatch_queue_t)queue
										  kinds:(NSArray*)kinds
{
	if(appId < 0)
		appId = -appId;
	
	if (queue == nil) {
		queue = dispatch_get_main_queue();
	}
		
	UDAggTransport* transport =
		[[UDAggTransport alloc] initWithAppId:appId nodeId:nodeId queue:queue];
	
	/*id<UDAdapter> adapter = [[UDNsdAdapter alloc] initWithDelegate:aggTransport appId:appId nodeId:nodeId peerToPeer:false queue:aggTransport.ioqueue];
	[transport addAdapter:adapter];
	return transport;*/

	if([kinds containsObject:@(UDTransportKindBluetooth)])
	{
		id<UDAdapter> adapter = [[UDBonjourAdapter alloc] initWithAppId:appId nodeId:nodeId delegate:transport queue:transport.ioqueue peerToPeer:true];

		[transport addAdapter:adapter];
	}

	if([kinds containsObject:@(UDTransportKindWifi)])
	{
		id<UDAdapter> adapter = [[UDBonjourAdapter alloc] initWithAppId:appId nodeId:nodeId delegate:transport queue:transport.ioqueue peerToPeer:false];
		
		[transport addAdapter:adapter];
	}

	return transport;
}

@end
