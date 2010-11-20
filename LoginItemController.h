//
//  LoginItemController.h
//  Sidestep
//
//  Created by Chetan Surpur on 11/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LoginItemController : NSObject {

}

+ (BOOL) willStartAtLogin:(NSURL *)itemURL;
+ (void) setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled;

@end
