//
//  ProxySetter.m
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Modified by Diogo Gomes on 8/8/12.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import "ProxySetter.h"
#import "AppUtilities.h"
#import <SystemConfiguration/SCNetworkConfiguration.h>
#import <SystemConfiguration/SCPreferences.h>
#import <SystemConfiguration/SCDynamicStore.h>

@implementation ProxySetter

- (id) init
{
    XLog(self, @"Get Auth");
    OSStatus               authErr = noErr;
    
    // Get Authorization
    rootFlags = kAuthorizationFlagDefaults
    |  kAuthorizationFlagExtendRights
    |  kAuthorizationFlagInteractionAllowed
    |  kAuthorizationFlagPreAuthorize;
    authErr = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, rootFlags, &auth);
    if (authErr != noErr) {
        auth = NULL;
    }
    return self;
}

/*
 * Toggle proxy ON/OFF
 *
 * return true on success
 * return false if an error occurs
 *
 */


- (BOOL)toggleProxy:(BOOL)on interface:(NSString *)interface port:(NSNumber *)port {

    XLog(self, [NSString stringWithFormat:@"toggleProxy %d on interface %@ using port %@", on, interface, port]);
    BOOL success = FALSE;
	
    
    if (auth == NULL) {
        XLog(self, [NSString stringWithFormat:@"No authorization has been granted to modify network configuration"]);
        return success;
    }
    
    // Get System Preferences Lock
    SCPreferencesRef prefsRef = SCPreferencesCreateWithAuthorization(NULL, CFSTR("sidestep"), NULL, auth);
    success = SCPreferencesLock(prefsRef, TRUE);
    if (!success) {
        XLog(self, @"Fail to obtain PreferencesLock");
        goto freePrefsRef;
    }
    
    // Get available network services
    SCNetworkSetRef networkSetRef = SCNetworkSetCopyCurrent(prefsRef);
    if(networkSetRef == NULL) {
        XLog(self, @"Fail to get available network services");
        goto freeNetworkSetRef;
    }
    
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
    
    XLog(self, [NSString stringWithFormat:@"Setting proxy for device %@", (NSString*)SCNetworkServiceGetName(networkServiceRef)]);

    // Get proxy protocol
    SCNetworkProtocolRef proxyProtocolRef = SCNetworkServiceCopyProtocol(networkServiceRef, kSCNetworkProtocolTypeProxies);
    if(proxyProtocolRef == NULL) {
        XLog(self, @"Couldn't acquire copy of proxyProtocol");
        goto freeResources;
    }
    
    NSDictionary *oldPreferences = (NSDictionary*)SCNetworkProtocolGetConfiguration(proxyProtocolRef);
    NSString *wantedHost = @"localhost";
    
    if(on) {//Turn proxy configuration ON
        [oldPreferences setValue: wantedHost forKey:(NSString*)kSCPropNetProxiesSOCKSProxy];
        [oldPreferences setValue:[NSNumber numberWithInt:1] forKey:(NSString*)kSCPropNetProxiesSOCKSEnable];
        [oldPreferences setValue:[NSNumber numberWithInteger:[port integerValue]] forKey:(NSString*)kSCPropNetProxiesSOCKSPort];
    } else {//Turn proxy configuration OFF
        [oldPreferences setValue:[NSNumber numberWithInt:0] forKey:(NSString*)kSCPropNetProxiesSOCKSEnable];
    }
        
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
    // If we reach this point that it's a wrap!
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
        
    return success;
}

- (BOOL) isProxyEnabled
{
	NSDictionary *proxies = (NSDictionary *)SCDynamicStoreCopyProxies(NULL);
    if(!proxies) return NO;
	
    BOOL enabled = [[proxies objectForKey:(NSString *)kSCPropNetProxiesSOCKSEnable] boolValue];

	if (proxies != NULL)
        CFRelease(proxies);
	
    XLog(self, enabled ? @"Proxy is Enabled" : @"Proxy is Disabled");
    
    return enabled;
}

-(void)dealloc {
    XLog(self, @"dealloc ProxySetter");
    
    AuthorizationFree(auth, rootFlags);
    
    [super dealloc];
}

@end
