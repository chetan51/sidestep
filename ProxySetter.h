//
//  ProxySetter.h
//  Sidestep
//
//  Created by Chetan Surpur on 11/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppUtilities.h"

@interface ProxySetter : NSObject {

}

- (void)turnProxyOn:(NSNumber *)port;
- (void)turnProxyOff;

@end
