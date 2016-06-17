//
//  UDLogger.h
//  Underdark
//
//  Created by Virl on 03/07/15.
//  Copyright (c) 2015 Underdark. All rights reserved.
//

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
	DDLogLevelAll       = NSUIntegerMax                           // 1111....11111 (DDLogLevelVerbose plus any other flags)
};

@protocol UDLogger <NSObject>

- (void)log:(BOOL)synchronous
	  level:(UDLogLevel)level
	   flag:(UDLogFlag)flag
	context:(NSInteger)context
	   file:(const char *)file
   function:(const char *)function
	   line:(NSUInteger)line
		tag:(id)tag
	 format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);

@end
