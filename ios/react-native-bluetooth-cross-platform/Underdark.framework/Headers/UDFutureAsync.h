//
// Created by Virl on 05/08/16.
// Copyright (c) 2016 Underdark. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UDFuture.h"

@class UDFutureAsync;

typedef void (^UDFutureAsyncHandler)(id _Nullable result);
typedef void (^UDFutureAsyncRetriever)(id _Nullable context, UDFutureAsyncHandler _Nonnull handler);

@interface UDFutureAsync<ResultType, ErrorType> : UDFuture<ResultType, ErrorType>

- (nonnull instancetype) init NS_UNAVAILABLE;

- (nonnull instancetype) initWithQueue:(nullable dispatch_queue_t)queue
								context:(nullable id)context
                                 block:(nonnull UDFutureAsyncRetriever)block NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype) initWithQueue:(nullable dispatch_queue_t)queue
								block:(nonnull UDFutureAsyncRetriever)block;

@end
