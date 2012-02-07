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

/*	
 *	Class methods
 *******************************************************************************
 */

- (id)init {
	
	self = [super init];
	
    if (self != nil)
    {
		defaults = [NSUserDefaults standardUserDefaults];
    }
	
    return self;	
	
}

- (void)dealloc {
	
	[defaults release];
	[super dealloc];
	
}

/*
 *	Data Storage
 *******************************************************************************
 */

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

- (void)setRemotePortNumber :(NSString *)port {
	
	[defaults setObject:port forKey:@"sidestep_RemotePortNumber"];
	[defaults synchronize];
	
}

- (NSString *)getRemotePortNumber {
	
	return [defaults stringForKey:@"sidestep_RemotePortNumber"];
	
}

- (void)setLocalPortNumber :(NSString *)port {
	
	[defaults setObject:port forKey:@"sidestep_LocalPortNumber"];
	[defaults synchronize];
	
}

- (NSString *)getLocalPortNumber {
	
	return [defaults stringForKey:@"sidestep_LocalPortNumber"];
	
}

- (void)setCompressSSHConnection:(BOOL)value {
	
	[defaults setBool:value forKey:@"sidestep_CompressSSHConnection"];
	[defaults synchronize];
	
}

- (BOOL)getCompressSSHConnection {
	
	return [defaults boolForKey:@"sidestep_CompressSSHConnection"];
	
}


- (void)setGrowlSetting :(BOOL)value {
	
	[defaults setBool:value forKey:@"sidestep_GrowlSetting"];
	[defaults synchronize];
	
}

- (BOOL)getGrowlSetting {
	
	return [defaults boolForKey:@"sidestep_GrowlSetting"];
	
}

/*
 *	Preferences
 *******************************************************************************
 */

- (void)setRanAtleastOnce :(BOOL)value {

	[defaults setBool:value forKey:@"sidestep_ranAtLeastOnce"];
	[defaults synchronize];
	
}

- (BOOL)ranAtleastOnce {

	return [defaults boolForKey:@"sidestep_ranAtLeastOnce"];

}

- (void)setRerouteAutomatically :(BOOL)value {

	[defaults setBool:value forKey:@"sidestep_rerouteAutomatically"];
	[defaults synchronize];
	
}

- (BOOL)rerouteAutomaticallyEnabled {

	return [defaults boolForKey:@"sidestep_rerouteAutomatically"];
	
}

- (void)setRunOnLogin :(BOOL)value {

	[defaults setBool:value forKey:@"sidestep_runOnLogin"];
	[defaults synchronize];
	
}

- (BOOL)runOnLogin {
	
	return [defaults boolForKey:@"sidestep_runOnLogin"];
	
}

- (void)setSelectedProxy:(NSString *)selection {
	
	[defaults setObject:selection forKey:@"sidestep_selectedProxy"];
	[defaults synchronize];
	
}

- (NSString *)selectedProxy {
	
	return [defaults stringForKey:@"sidestep_selectedProxy"];
	
}

- (void)setSelectedVPNService:(NSString *)selection {
	
	[defaults setObject:selection forKey:@"sidestep_selectedVPNService"];
	[defaults synchronize];
	
}

- (NSString *)selectedVPNService {
	
	return [defaults stringForKey:@"sidestep_selectedVPNService"];
	
}

@end
