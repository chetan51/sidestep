//
//  VPNInterfacer.h
//  Sidestep
//
//  Created by Chetan Surpur on 12/6/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppUtilities.h"

@interface VPNInterfacer : NSObject {
	
}

- (BOOL)turnVPNOnOrOff:(NSString *)serviceName withState:(BOOL)state;

@end
