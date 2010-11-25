//
//  SSHConnector.m
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import "SSHConnector.h"
#import "AppUtilities.h"
#include <signal.h>
#include <unistd.h>

@implementation SSHConnector

/*	
 *	Constants
 */

NSString *SSHLogPath = @"/tmp/sidestepssh.log";
NSString *terminateCommand = @"Sidestep: Terminate connection attempt manually\n";

/*	
 *	Opens SSH connection, asking the user for password and storing it in the keychain upon request.
 *	Calls a given callback function on each notable event.
 *
 *	argument: callback object to be called upon notable event
 *	argument: callback selector on object to be called upon opening connection
 *	argument: callback selector on object to be called upon successful connection
 *	argument: callback selector on object to be called upon failed connection
 *	argument: username for server
 *	argument: hostname for server
 *	argument: remoteport for server
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)openSSHConnectionAndNotifyObject:(id)object
					 withOpeningSelector:(SEL)openingSelector
					 withSuccessSelector:(SEL)successSelector
					 withFailureSelector:(SEL)failureSelector
							withUsername:(NSString *)username
							withHostname:(NSString *)hostname
							withRemotePort:(NSString *)remoteport
					   withLocalBindPort:(NSNumber *)localPort {
	
	XLog(self, @"Opening SSH connection");
	XLog(self, @"User: %@",username);
	XLog(self, @"Host: %@",hostname);
	
	NSTask *taskObject = [[[NSTask alloc] init] autorelease];
	
	// Setup the pipes on the task
	NSPipe *outputPipe = [NSPipe pipe];
	NSPipe *errorPipe = [NSPipe pipe];
	
	[taskObject setStandardOutput:outputPipe];
	[taskObject setStandardInput:[NSFileHandle fileHandleWithNullDevice]];	// It's important that the standard input is set to null here. 
																			// This is sometimes required in order to get SSH to use the
																			// Askpass program rather then prompt the user interactively.
	[taskObject setStandardError:errorPipe];
	
	// Get the path of the Askpass program, which is included as part of the main application bundle
	NSString *askPassPath = [NSBundle pathForResource:@"SSHAskPass"
											   ofType:@""
										  inDirectory:[[NSBundle mainBundle] bundlePath]];
	
	XLog(self, @"AskPass path: %@",askPassPath);
	
	if (askPassPath == nil) {
		return FALSE;
	}
	
	// Set up environment variables for the task
	NSDictionary *currentEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *newEnvironment =	[NSMutableDictionary dictionaryWithObjectsAndKeys:
											 @"NONE", @"DISPLAY", // It's important that Display is set so that ssh will use Askpass. The actual value is not important though 
											 askPassPath, @"SSH_ASKPASS",
											 username,@"AUTH_USERNAME",
											 hostname,@"AUTH_HOSTNAME",
											 nil];
	[newEnvironment setObject:[currentEnvironment objectForKey:@"SSH_AUTH_SOCK"] forKey:@"SSH_AUTH_SOCK"]; // Environment variable needed for key based authentication	
	
	NSLog(@"Environment: %@",newEnvironment);
	
	// Set the task's environment
	[taskObject setEnvironment:newEnvironment];
	
	// Set up arguments for the ssh command
	NSMutableArray *args = [[NSMutableArray new] autorelease];
	[args addObject:[NSString stringWithFormat:@"%@@%@",username,hostname]];
	[args addObject:[NSString stringWithFormat:@"-D %@", localPort]];
	[args addObject:[NSString stringWithFormat:@"-p %@", remoteport]];
	[args addObject:[NSString stringWithString:@"-N"]];
	[args addObject:[NSString stringWithString:@"-v"]];
	[args addObject:[NSString stringWithString:@"-o TCPKeepAlive=yes"]];
	[args addObject:[NSString stringWithString:@"-o ServerAliveInterval=30"]];
	
	// Delete previous connection's log file
	[[NSFileManager defaultManager]
	 removeItemAtPath:SSHLogPath
	 error:nil];
	
	// Create log file for ssh command to output to
	[[NSFileManager defaultManager]
     createFileAtPath:SSHLogPath
     contents:nil
     attributes:nil];
	
	// Set error output of ssh command to the log file
	NSFileHandle *logHandle = [NSFileHandle fileHandleForWritingAtPath:SSHLogPath];
	[taskObject setStandardError:logHandle];
	
	// Set up task arguments and launch path
	[taskObject setArguments:args];
	[taskObject setLaunchPath:@"/usr/bin/ssh"];
	
	// Launch task
	[taskObject launch];
	
	// Notify opening callback selector on object
	[object performSelector:openingSelector withObject:taskObject];
	
	// Watch the connection for changes - To do: this needs to happen before the task is launched
	if (![self watchSSHConnectionAndOnOpenOrErrorNotifyObject:object
										 withSuccessSelector:successSelector
										 withFailureSelector:failureSelector
											  withConnection:taskObject]) {
		return FALSE;
	}
	
	return TRUE;
	
}

/*	
 *	Watches given SSH connection's log file for changes.
 *	Calls a given callback function on each notable event.
 *
 *	argument: callback object to be called upon notable event
 *	argument: callback selector on object to be called upon successful connection
 *	argument: callback selector on object to be called upon failed connection
 *	argument: connection's task that is being watched
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)watchSSHConnectionAndOnOpenOrErrorNotifyObject:(id)object
								   withSuccessSelector:(SEL)successSelector
								   withFailureSelector:(SEL)failureSelector
										withConnection:(NSTask *)connection {

	XLog(self, @"Watching SSH connection for open or error");
	
	NSTask *task = [[[NSTask alloc] init] autorelease];
	
	// Setup the pipes on the task
	NSPipe *outputPipe = [NSPipe pipe];
	NSPipe *errorPipe = [NSPipe pipe];
	
	[task setStandardOutput:outputPipe];
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardError:errorPipe];
	
	// Set up arguments to the task
	NSMutableArray *args = [[NSMutableArray new] autorelease];
	[args addObject:SSHLogPath];
	
	// Get the path of the task, which is included as part of the main application bundle
	NSString *taskPath = [NSBundle pathForResource:@"WatchSSHConnectionForChanges"
											ofType:@"sh"
									   inDirectory:[[NSBundle mainBundle] bundlePath]];
	
	if (taskPath == nil) {
		return FALSE;
	}
	
	// Set task's arguments and launch path
	[task setArguments:args];
	[task setLaunchPath:taskPath];
	
	// Before launching the task, get a filehandle for reading its output
	NSFileHandle *readHandle = [[task standardOutput] fileHandleForReading];
	
	// Launch task
	[task launch];
	
	// Read task's output data
	NSData *readData;
	while ((readData = [readHandle availableData]) && [readData length]) {
		NSString *readString = [[NSString alloc] initWithData:readData encoding:NSASCIIStringEncoding];

		XLog(self, @"SSH Connection Watcher said: %@", readString);
		
		//	Return values of SSH Connection Watcher:
		//		1 - Connection successful
		//		2 - Authentication error
		//		3 - Server not found
		//		4 - Connection timed out
		//		5 - Manually terminated connection attempt

		if ([readString isEqualToString:@"1"]) {								// If connection was successful,
			[object performSelector:successSelector withObject:connection];		// call the success callback function
		}
		else {																	// If connection was not successful,
			[object performSelector:failureSelector withObject:readString];		// call the failure callback function
		}
	}
	
	return TRUE;
	
}

/*	
 *	Waits for given SSH connection's task to close, and then calls a given callback function.
 *
 *	argument: callback object to be called upon notable event
 *	argument: callback selector on object to be called upon connection close
 *	argument: connection's task that is being watched
 *	return: void
 */

- (void)watchSSHConnectionAndOnCloseNotifyObject:(id)object
									withSelector:(SEL)selector
								  withConnection:(NSTask *)connection {
	
	XLog(self, @"Watching SSH connection for close");
	
	// Wait for connection's task to exit
    [connection waitUntilExit];

	// Notify close callback selector on object
	[object performSelector:selector];

}

/*	
 *	Manually terminates SSH connection attempt by inserting terminate message into the SSH connection log.
 *
 *	return: void
 */

- (void)terminateSSHConnectionAttempt {
	
	XLog(self, @"Terminating SSH connection attempt");
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:SSHLogPath]) {					// If file exists
		XLog(self, @"Writing terminate command to SSH connection log file");
		
		NSFileHandle *logHandle = [NSFileHandle fileHandleForWritingAtPath:SSHLogPath];		// Get log file handle for writing
		[logHandle seekToEndOfFile];														// Append to file
		[logHandle writeData:[terminateCommand dataUsingEncoding:NSUTF8StringEncoding]];	// Write terminate command to file
	}
		
}

/*	
 *	Kills given SSH connection's task by process ID (PID).
 *
 *	argument: process ID to kill
 *	return: void
 */

- (void)killSSHConnectionForPID :(int)pid {
	
	XLog(self, @"Killing connection with PID: %d", pid);
	
	kill(pid, SIGTERM);

}

@end
