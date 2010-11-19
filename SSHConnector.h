//
//  SSHConnector.h
//  Sidestep
//
//  Created by Chetan Surpur on 10/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SSHConnector : NSObject {
	
}

- (void)openSSHConnectionAndNotifyObject:(id)object
					 withOpeningSelector:(SEL)openingSelector
					 withSuccessSelector:(SEL)successSelector
					 withFailureSelector:(SEL)failureSelector
							withUsername:(NSString *)username
							withHostname:(NSString *)hostname
					   withLocalBindPort:(NSNumber *)localPort;

- (void)watchSSHConnectionAndOnOpenOrErrorNotifyObject:(id)object
								   withSuccessSelector:(SEL)successSelector
								   withFailureSelector:(SEL)failureSelector
										withConnection:(NSTask *)connection;

- (void)watchSSHConnectionAndOnCloseNotifyObject:(id)object
									withSelector:(SEL)selector
								  withConnection:(NSTask *)connection;

- (void)terminateSSHConnectionAttempt;

- (void)killSSHConnectionForPID :(int)pid;

@end
