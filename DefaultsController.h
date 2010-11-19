//
//  DefaultsController.h
//  Sidestep
//
//  Created by Chetan Surpur on 10/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DefaultsController : NSObject {
	NSUserDefaults *defaults;
}

- (void)saveSSHConnectionPID :(int)pid;
- (int)getSSHConnectionPID;

- (NSString *)getServerUsername;
- (NSString *)getServerHostname;

- (int)rerouteAutomaticallyEnabled;

@end
