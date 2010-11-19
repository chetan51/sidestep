//
//  DefaultsController.m
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import "DefaultsController.h"
#import "AppUtilities.h"

@implementation DefaultsController

- (id)init {
	
	self = [super init];
	
    if (self != nil)
    {
		defaults = [NSUserDefaults standardUserDefaults];
    }
	
    return self;	
	
}

- (void)saveSSHConnectionPID :(int)pid {
	
	XLog(self, @"Saving PID %d to user defaults", pid);
	
	[defaults setInteger:pid forKey:@"sidestep_SSHConnectionPID"];
	[defaults synchronize];

}

- (int)getSSHConnectionPID {
	
	return [defaults integerForKey:@"sidestep_SSHConnectionPID"];

}

- (NSString *)getServerUsername {
	
	return [defaults stringForKey:@"sidestep_ServerUsername"];
	
}

- (NSString *)getServerHostname {
	
	return [defaults stringForKey:@"sidestep_ServerHostname"];
	
}

/*
 * Preferences
 */

- (int)rerouteAutomaticallyEnabled {

	return [defaults integerForKey:@"sidestep_rerouteAutomatically"];
	
}

- (void)dealloc {
	
	[defaults release];
	[super dealloc];
	
}

@end
