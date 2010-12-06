//
//  ProxySetter.h
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProxySetter : NSObject {

}

- (BOOL)turnAirportProxyOn:(NSNumber *)port;
- (BOOL)turnAirportProxyOff;

- (BOOL)turnVPNOnOrOff:(NSString *)serviceName withState:(BOOL)state;

@end
