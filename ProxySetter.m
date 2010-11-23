//
//  ProxySetter.m
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import "ProxySetter.h"


@implementation ProxySetter

/*
 *	Switches system's SOCKS proxy to the SSH tunnel previously opened.
 *	
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)turnProxyOn:(NSNumber *)port {
	
	XLog(self, @"Turning proxy on for port: %@", port);
	
	NSTask *task = [[[NSTask alloc] init] autorelease];
	
	// Setup the pipes on the task
	NSPipe *outputPipe = [NSPipe pipe];
	NSPipe *errorPipe = [NSPipe pipe];
	
	[task setStandardOutput:outputPipe];
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardError:errorPipe];
	
	// Set up arguments to the task
	NSArray *args = [NSArray arrayWithObject:[NSString stringWithFormat:@"%d", [port intValue]]];
	
	// Get the path of the task, which is included as part of the main application bundle
	NSString *taskPath = [NSBundle pathForResource:@"TurnProxyOn"
											ofType:@"sh"
									   inDirectory:[[NSBundle mainBundle] bundlePath]];
	
	if (!taskPath) {
		return FALSE;
	}
	
	// Set task's arguments and launch path
	[task setArguments:args];
	[task setLaunchPath:taskPath];
	
	// Launch task
	[task launch];
	
	return TRUE;
	
}

/*
 *	Switches system's SOCKS proxy off.
 *	
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)turnProxyOff {
	
	XLog(self, @"Turning proxy off");
	
	NSTask *task = [[[NSTask alloc] init] autorelease];
	
	// Setup the pipes on the task
	NSPipe *outputPipe = [NSPipe pipe];
	NSPipe *errorPipe = [NSPipe pipe];
	
	[task setStandardOutput:outputPipe];
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardError:errorPipe];
	
	// Get the path of the task, which is included as part of the main application bundle
	NSString *taskPath = [NSBundle pathForResource:@"TurnProxyOff"
											ofType:@"sh"
									   inDirectory:[[NSBundle mainBundle] bundlePath]];
	
	if (!taskPath) {
		return FALSE;
	}	
	
	// Set task's launch path
	[task setLaunchPath:taskPath];
	
	// Launch task
	[task launch];
	
	return TRUE;
	
}

@end
