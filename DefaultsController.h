//
//  DefaultsController.h
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DefaultsController : NSObject {
	NSUserDefaults *defaults;
}

- (void)saveSSHConnectionPID :(int)pid;
- (int)getSSHConnectionPID;

- (NSString *)getServerUsername;
- (NSString *)getServerHostname;

- (void)setRanAtleastOnce :(BOOL)value;
- (BOOL)ranAtleastOnce;

- (void)setRerouteAutomatically :(BOOL)enabled;
- (BOOL)rerouteAutomaticallyEnabled;

- (void)setRunOnLogin :(BOOL)enabled;
- (BOOL)runOnLogin;

@end
