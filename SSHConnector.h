//
//  SSHConnector.h
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SSHConnector : NSObject {
	
}

- (NSTask *)sshTaskWithUsername:(NSString *)username
				   withHostname:(NSString *)hostname
				 withRemotePort:(NSString *)remoteport
			  withLocalBindPort:(NSNumber *)localPort
		withAdditionalArguments:(NSString *)additionalArgs
			 withSSHCompression:(BOOL)sshCompression;

- (BOOL)openSSHConnectionAndNotifyObject:(id)object
					 withOpeningSelector:(SEL)openingSelector
					 withSuccessSelector:(SEL)successSelector
					 withFailureSelector:(SEL)failureSelector
							withUsername:(NSString *)username
							withHostname:(NSString *)hostname
						  withRemotePort:(NSString *)remoteport
					   withLocalBindPort:(NSNumber *)localPort
				 withAdditionalArguments:(NSString *)additionalArgs
                      withSSHCompression:(BOOL)sshCompression;

- (BOOL)watchSSHConnectionAndOnOpenOrErrorNotifyObject:(id)object
								   withSuccessSelector:(SEL)successSelector
								   withFailureSelector:(SEL)failureSelector
										withConnection:(NSTask *)connection;

- (void)watchSSHConnectionAndOnCloseNotifyObject:(id)object
									withSelector:(SEL)selector
								  withConnection:(NSTask *)connection;

- (void)terminateSSHConnectionAttempt;

- (void)killSSHConnectionForPID :(int)pid;

@end
