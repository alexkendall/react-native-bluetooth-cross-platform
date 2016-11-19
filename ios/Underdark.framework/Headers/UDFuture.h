//
// Created by Virl on 31/07/16.
// Copyright (c) 2016 Underdark. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^UDFutureCallback)(bool success, id _Nullable result, id _Nullable error);

@interface UDFuture<ResultType, ErrorType> : NSObject

- (void) listen:(nullable dispatch_queue_t)queue
          block:(nonnull void (^)(bool success, ResultType _Nullable result, ErrorType _Nullable error))block;

@end
