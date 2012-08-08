//
//  ProxySetter.h
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProxySetter : NSObject {
    AuthorizationRef       auth;
    AuthorizationFlags rootFlags;
}
- (BOOL)toggleProxy:(BOOL)on interface:(NSString *)interface port:(NSNumber *)port;

- (void)dealloc;

@end
