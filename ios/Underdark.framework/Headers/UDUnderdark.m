//
//  UDUnderdark.m
//  Solidarity
//
//  Created by Virl on 29/06/15.
//  Copyright (c) 2015 Glint. All rights reserved.
//

#import "UDUnderdark.h"

#import "UDLogging.h"
#import "UDAggTransport.h"
#import "UDBonjourTransport.h"
#import "UDNsdTransport.h"

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
									   delegate:(id<UDTransportDelegate>)delegate
										  queue:(dispatch_queue_t)queue
										  kinds:(NSArray*)kinds
{
	if(appId < 0)
		appId = -appId;
	
	if (queue == nil) {
		queue = dispatch_get_main_queue();
	}
		
	UDAggTransport* aggTransport =
		[[UDAggTransport alloc] initWithAppId:appId nodeId:nodeId delegate:delegate queue:queue];
	
	/*id<UDTransport> childTransport = [[UDNsdTransport alloc] initWithDelegate:aggTransport appId:appId nodeId:nodeId peerToPeer:false queue:aggTransport.queue];
	[aggTransport addTransport:childTransport];
	return aggTransport;*/
	
	if([kinds containsObject:@(UDTransportKindWifi)]
	   || [kinds containsObject:@(UDTransportKindBluetooth)])
	{
		bool peerToPeer = [kinds containsObject:@(UDTransportKindBluetooth)];
		
		id<UDTransport> childTransport = [[UDBonjourTransport alloc] initWithAppId:appId nodeId:nodeId delegate:aggTransport queue:aggTransport.queue peerToPeer:peerToPeer];
		
		[aggTransport addTransport:childTransport];
	}
	
	return aggTransport;
}

@end
