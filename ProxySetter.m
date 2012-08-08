//
//  ProxySetter.m
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import "ProxySetter.h"
#import "AppUtilities.h"
#import <SystemConfiguration/SCNetworkConfiguration.h>
#import <SystemConfiguration/SCPreferences.h>
#import <SystemConfiguration/SCDynamicStore.h>

@implementation ProxySetter

/*
 *	Switches Airport's SOCKS proxy to the SSH tunnel previously opened.
 *
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)turnAirportProxyOn:(NSNumber *)port {
    
    return [self turnProxyOn:port interface:@"Airport"];
    
}

/*
 *	Switches WiFi's SOCKS proxy to the SSH tunnel previously opened.
 *
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)turnWiFiProxyOn:(NSNumber *)port {
    
    return [self turnProxyOn:port interface:@"Wi-Fi"];
    
}

/*
 *	Switches given interface's SOCKS proxy to the SSH tunnel previously opened.
 *
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)turnProxyOn:(NSNumber *)port interface:(NSString *)interface {

    BOOL success = FALSE;
	
	XLog(self, @"Turning proxy on for port: %@", port);
    
    OSStatus               authErr = noErr;
    AuthorizationRef       auth;
    
    // Get Authorization
    AuthorizationFlags rootFlags = kAuthorizationFlagDefaults
    |  kAuthorizationFlagExtendRights
    |  kAuthorizationFlagInteractionAllowed
    |  kAuthorizationFlagPreAuthorize;
    authErr = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, rootFlags, &auth);
    
    if (authErr != noErr) {
        XLog(self, [NSString stringWithFormat:@" Error in AuthorizationCreate, CODE: %d", authErr]);
        goto freeAuth;
    }
    
    // Get System Preferences Lock
    SCPreferencesRef prefsRef = SCPreferencesCreateWithAuthorization(NULL, CFSTR("sidestep"), NULL, auth);
    success = SCPreferencesLock(prefsRef, NO);
    if (!success) {
        XLog(self, @"Fail to obtain PreferencesLock");
        goto freePrefsRef;
    }
    
    // Get available network services
    SCNetworkSetRef networkSetRef = SCNetworkSetCopyCurrent(prefsRef);
    if(networkSetRef == NULL)
        goto freeNetworkSetRef;
    
    //Look up interface entry
    CFArrayRef networkServicesArrayRef = SCNetworkSetCopyServices(networkSetRef);
    SCNetworkServiceRef networkServiceRef = NULL;
    for (long i = 0; i < CFArrayGetCount(networkServicesArrayRef); i++) {
        networkServiceRef = CFArrayGetValueAtIndex(networkServicesArrayRef, i);
        if([(NSString *)SCNetworkServiceGetName(networkServiceRef) isEqualToString:interface])
            break;
        else
            networkServiceRef = NULL;
    }
    if (networkServiceRef == NULL) {
        XLog(self, [NSString stringWithFormat:@"No system interface matching %@", interface]);
        goto freeNetworkServicesArrayRef;
    }
    
    XLog(self, [NSString stringWithFormat:@"Setting proxy on device %@", (NSString*)SCNetworkServiceGetName(networkServiceRef)]);

    // Get proxy protocol
    SCNetworkProtocolRef proxyProtocolRef = SCNetworkServiceCopyProtocol(networkServiceRef, kSCNetworkProtocolTypeProxies);
    if(proxyProtocolRef == NULL) {
        XLog(self, @"Couldn't acquire copy of proxyProtocol");
        goto freeResources;
    }
    
    NSDictionary *oldPreferences = (NSDictionary*)SCNetworkProtocolGetConfiguration(proxyProtocolRef);
    NSString *wantedHost = @"localhost";
    
    [oldPreferences setValue: wantedHost forKey:(NSString*)kSCPropNetProxiesSOCKSProxy];
    [oldPreferences setValue:[NSNumber numberWithInt:1] forKey:(NSString*)kSCPropNetProxiesSOCKSEnable];
    [oldPreferences setValue:[NSNumber numberWithInteger:[port integerValue]] forKey:(NSString*)kSCPropNetProxiesSOCKSPort];
    
    success = SCNetworkProtocolSetConfiguration(proxyProtocolRef, (CFDictionaryRef)oldPreferences);
    if(!success) {
        XLog(self, @"Failed to set Protocol Configuration");
        goto freeResources;
    }
    
    success = SCPreferencesCommitChanges(prefsRef);
    if(!success) {
        XLog(self, @"Failed to Commit Changes");
        goto freeResources;
    }
    
    success = SCPreferencesApplyChanges(prefsRef);
    if(!success) {
        XLog(self, @"Failed to Apply Changes");
        goto freeResources;
    }
    
    success = TRUE;
    
    //Free Resources
freeResources:
    CFRelease(proxyProtocolRef);
freeNetworkServicesArrayRef:
    CFRelease(networkServicesArrayRef);
freeNetworkSetRef:
	CFRelease(networkSetRef);    
freePrefsRef:
    SCPreferencesUnlock(prefsRef);
    CFRelease(prefsRef);
freeAuth:
    AuthorizationFree(auth, rootFlags);
        
    return success;
	
}

/*
 *	Switches Airport's SOCKS proxy off.
 *
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)turnAirportProxyOff {
	
    return [self turnProxyOff:@"Airport"];
    
}

/*
 *	Switches WiFi's SOCKS proxy off.
 *
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)turnWiFiProxyOff {
	
    return [self turnProxyOff:@"Wi-Fi"];
    
}

/*
 *	Switches given interface's SOCKS proxy off.
 *
 *	return: true on success
 *	return: false if task path not found
 */

- (BOOL)turnProxyOff:(NSString *)interface {
    
	XLog(self, @"Turning proxy off");
	
	NSTask *task = [[[NSTask alloc] init] autorelease];
	
	// Setup the pipes on the task
	NSPipe *outputPipe = [NSPipe pipe];
	NSPipe *errorPipe = [NSPipe pipe];
	
	[task setStandardOutput:outputPipe];
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardError:errorPipe];
	
	// Set up arguments to the task
	NSArray *args = [NSArray arrayWithObject:[NSString stringWithString:interface]];
	
	// Get the path of the task, which is included as part of the main application bundle
	NSString *taskPath = [NSBundle pathForResource:@"TurnProxyOff"
											ofType:@"sh"
									   inDirectory:[[NSBundle mainBundle] bundlePath]];
	
	if (!taskPath) {
		return FALSE;
	}
	
	// Set task's arguments and launch path
	[task setArguments:args];
	[task setLaunchPath:taskPath];
	
	// Launch task
	[task launch];
	
	return TRUE;
	
}

@end
