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

#import "UDFuture.h"

@import Foundation;

@interface UDSource<DataType> : NSObject

/**
 * Future that retrieves source's data.
 */
@property (nonatomic, readonly, nonnull) UDFuture<DataType, id>* future;

/**
 * Unique ID for the data being sent (can be nil).
 * Used for automatic data sharing between links.
 */
@property (nonatomic, readonly, nullable) NSString* dataId;

- (nullable instancetype) init NS_UNAVAILABLE;

- (nonnull instancetype) initWithFuture:(nonnull UDFuture<DataType, id>*)future
                                 dataId:(nullable NSString*)dataId NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype) initWithFuture:(nonnull UDFuture<DataType, id>*)future;

@end
