//
//  NetworkNotifier.h
//  HardwareGrowler
//
//  Created by Ingmar Stein on 18.02.05. Modified by Chetan Surpur.
//  Copyright 2005 The Growl Project. All rights reserved.
//

@interface NetworkNotifier : NSObject
{
	id airportConnectionNotifyObject;
	SEL airportConnectionNotifySelector;
}

- (void)listenForAirportConnectionAndNotifyObject:(id)object withSelector:(SEL)selector;
- (void)getNetworkSecurityTypeAndNotifyObject:(id)object withSelector:(SEL)selector;

@end
