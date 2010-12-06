//
//  VPNInterfacer.h
//  Sidestep
//
//  Created by Chetan Surpur on 12/6/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VPNInterfacer : NSObject {
	
}

- (NSArray *)getListOfVPNServices;
- (BOOL)turnVPNOnOrOff:(NSString *)serviceName withState:(BOOL)state;

@end
