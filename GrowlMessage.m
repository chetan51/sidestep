//
//  GrowlMessage.m
//  Sidestep
//
//  Created by Steve Warren on 11/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GrowlMessage.h"
#import <Growl/Growl.h>

@implementation GrowlMessage


- (id)init {
	
	self = [super init];
	
    if (self != nil)
    {
		setting = [NSUserDefaults standardUserDefaults];    
	}
	
    return self;	
	
}

- (void)dealloc {
	
	[setting release];
	[super dealloc];
	
}

- (void) message: (NSString *)sendMessage {
	
	if([setting boolForKey:@"sidestep_GrowlSetting"] == TRUE) {
		[GrowlApplicationBridge notifyWithTitle: @"Sidestep"
								description: sendMessage
								notificationName:@"GrowlNotification"
								iconData: nil
								priority: 0
								isSticky: NO
								clickContext: nil];
	}
}

@end
