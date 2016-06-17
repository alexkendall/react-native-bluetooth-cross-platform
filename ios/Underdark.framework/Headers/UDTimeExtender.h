//
//  UDTimeExtender.h
//  Underdark
//
//  Created by Virl on 01/07/15.
//  Copyright (c) 2015 Underdark. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UDTimeExtender;

@protocol UDSuspendListener <NSObject>

- (void)applicationWillSuspend:(UDTimeExtender*)timeExtender;

@end

@interface UDTimeExtender : NSObject

+ (void) registerListener:(id<UDSuspendListener>)listener;

- (instancetype) init;
- (instancetype) initWithName:(NSString*)name NS_DESIGNATED_INITIALIZER;

- (void) extendBackgroundTime;
- (void) cancel;

@end
