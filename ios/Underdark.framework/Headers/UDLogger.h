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

typedef NS_OPTIONS(NSUInteger, UDLogFlag) {
	UDLogFlagError      = (1 << 0), // 0...00001
	UDLogFlagWarning    = (1 << 1), // 0...00010
	UDLogFlagInfo       = (1 << 2), // 0...00100
	UDLogFlagDebug      = (1 << 3), // 0...01000
	UDLogFlagVerbose    = (1 << 4)  // 0...10000
};

typedef NS_ENUM(NSUInteger, UDLogLevel) {
	UDLogLevelOff       = 0,
	UDLogLevelError     = (UDLogFlagError),                       // 0...00001
	UDLogLevelWarning   = (UDLogLevelError   | UDLogFlagWarning), // 0...00011
	UDLogLevelInfo      = (UDLogLevelWarning | UDLogFlagInfo),    // 0...00111
	UDLogLevelDebug     = (UDLogLevelInfo    | UDLogFlagDebug),   // 0...01111
	UDLogLevelVerbose   = (UDLogLevelDebug   | UDLogFlagVerbose), // 0...11111
	UDLogLevelAll       = NSUIntegerMax                           // 1111....11111 (DDLogLevelVerbose plus any other flags)
};

@protocol UDLogger <NSObject>

- (void)log:(BOOL)asynchronous
	  level:(UDLogLevel)level
	   flag:(UDLogFlag)flag
	context:(NSInteger)context
	   file:(const char * _Null_unspecified)file
   function:(const char * _Null_unspecified)function
	   line:(NSUInteger)line
		tag:(id _Nullable)tag
	message:(NSString * _Nonnull)message;

@end
