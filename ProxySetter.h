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
- (BOOL)turnWiFiProxyOn:(NSNumber *)port;
- (BOOL)turnProxyOn:(NSNumber *)port interface:(NSString *)interface;

- (BOOL)turnAirportProxyOff;
- (BOOL)turnWiFiProxyOff;
- (BOOL)turnProxyOff:(NSString *)interface;

@end
