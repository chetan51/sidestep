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
- (void) message: (NSString *)sendMessage {
	[GrowlApplicationBridge notifyWithTitle: @"Sidestep"
								description: sendMessage
						   notificationName:@"GrowlNotification"
								   iconData: nil
								   priority: 0
								   isSticky: NO
							   clickContext: nil];
}

@end
