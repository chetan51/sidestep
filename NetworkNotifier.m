//
//  NetworkNotifier.m
//  Sidestep
//
//	From NetworkNotifier.m
//  HardwareGrowler
//
//  Created by Ingmar Stein on 18.02.05. Modified by Chetan Surpur on 11/19/10.
//  Copyright 2005 The Growl Project. All rights reserved.
//  Copyright (C) 2004 Scott Lamb <slamb@slamb.org>
//

#import <Cocoa/Cocoa.h>

#include "NetworkNotifier.h"
#include "AppController.h"
#include "AppUtilities.h"
#include <SystemConfiguration/SystemConfiguration.h>

/* @"Link Status" == 1 seems to mean disconnected */
#define AIRPORT_DISCONNECTED 1

static CFDictionaryRef airportStatus;

/** A reference to the SystemConfiguration dynamic store. */
static SCDynamicStoreRef dynStore;

/** Our run loop source for notification. */
static CFRunLoopSourceRef rlSrc;

@implementation NetworkNotifier

- (void)airportStatusChange:(NSDictionary *)newValue {
//	NSLog(CFSTR("AirPort event"));
	
	CFDataRef newBSSID = NULL;
	if (newValue)
		newBSSID = (CFDataRef)[newValue objectForKey:@"BSSID"];

	CFDataRef oldBSSID = NULL;
	if (airportStatus)
		oldBSSID = CFDictionaryGetValue(airportStatus, CFSTR("BSSID"));

	if (newValue && oldBSSID != newBSSID && !(newBSSID && oldBSSID && CFEqual(oldBSSID, newBSSID))) {
		NSNumber *linkStatus = [newValue objectForKey:@"Link Status"];
		NSNumber *powerStatus = [newValue objectForKey:@"Power Status"];
		if (linkStatus || powerStatus) {
			int status = 0;
			if (linkStatus) {
				status = [linkStatus intValue];
			} else if (powerStatus) {
				status = [powerStatus intValue];
				status = !status;
			}
			if (status == AIRPORT_DISCONNECTED) {
				CFStringRef networkName = CFDictionaryGetValue(airportStatus, CFSTR("SSID_STR"));
				if (!networkName)
					networkName = CFDictionaryGetValue(airportStatus, CFSTR("SSID"));
				//AppController_airportDisconnect(networkName);
			} else {
				NSString *networkName = [newValue objectForKey:@"SSID_STR"];
				if (!networkName)
					networkName = [newValue objectForKey:@"SSID"];
				//AppController_airportConnect((CFStringRef)networkName, CFDataGetBytePtr(newBSSID));
				
				XLog(self, @"Connected to network");
				
				if (airportConnectionNotifyObject && airportConnectionNotifySelector) {					// If callback object and selector are defined,
					[airportConnectionNotifyObject performSelector:airportConnectionNotifySelector];		// call the callback selector
				}
			}
		}
	}

	if (airportStatus)
		CFRelease(airportStatus);

	if (newValue)
		airportStatus = CFRetain(newValue);
	else
		airportStatus = NULL;
}

- (void)listenForAirportConnectionAndNotifyObject:(id)object withSelector:(SEL)selector {
	
	airportConnectionNotifyObject = object;
	airportConnectionNotifySelector = selector;
	
}

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
	NetworkNotifier *self = info;

	CFIndex count = CFArrayGetCount(changedKeys);
	for (CFIndex i=0; i<count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
		
		if (CFStringCompare(key,
							CFSTR("State:/Network/Interface/en1/AirPort"),
							0) == kCFCompareEqualTo) {
			CFDictionaryRef newValue = SCDynamicStoreCopyValue(store, key);
			[self airportStatusChange:(NSDictionary *)newValue];
			if (newValue)
				CFRelease(newValue);
		}
	}
}

- (id)init {
	if (!(self = [super init])) return nil;

	airportConnectionNotifyObject = nil;
	airportConnectionNotifySelector = nil;
	
	SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};

	dynStore = SCDynamicStoreCreate(kCFAllocatorDefault,
									CFBundleGetIdentifier(CFBundleGetMainBundle()),
									scCallback,
									&context);
	if (!dynStore) {
		NSLog(@"SCDynamicStoreCreate() failed: %s", SCErrorString(SCError()));
		[self release];
		return nil;
	}
	
	const CFStringRef keys[3] = {
		CFSTR("State:/Network/Interface/en0/Link"),
		CFSTR("State:/Network/Global/IPv4"),
		CFSTR("State:/Network/Interface/en1/AirPort")
	};
	CFArrayRef watchedKeys = CFArrayCreate(kCFAllocatorDefault,
										   (const void **)keys,
										   3,
										   &kCFTypeArrayCallBacks);
	if (!SCDynamicStoreSetNotificationKeys(dynStore,
										   watchedKeys,
										   NULL)) {
		CFRelease(watchedKeys);
		NSLog(@"SCDynamicStoreSetNotificationKeys() failed: %s", SCErrorString(SCError()));
		CFRelease(dynStore);
		dynStore = NULL;
		
		[self release];
		return nil;
	}
	CFRelease(watchedKeys);
	
	rlSrc = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynStore, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
	CFRelease(rlSrc);
	
	airportStatus = SCDynamicStoreCopyValue(dynStore, CFSTR("State:/Network/Interface/en1/AirPort"));
	
	return self;
}

/*
 *	Get the currently connected network's security type and notify given object / selector.
 *
 *	return: true on success
 *	return: false if task path not found
 */
- (BOOL)getNetworkSecurityTypeAndNotifyObject:(id)object withSelector:(SEL)selector {
	
	XLog(self, @"Getting network security type");
	
	NSTask *task = [[NSTask alloc] init];
	
	// Setup the pipes on the task
	NSPipe *outputPipe = [NSPipe pipe];
	NSPipe *errorPipe = [NSPipe pipe];
	
	[task setStandardOutput:outputPipe];
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardError:errorPipe];
	
	// Get the path of the script, which we've included as part of the main application bundle
	NSString *taskPath = [NSBundle pathForResource:@"GetNetworkSecurityType"
											ofType:@"sh"
									   inDirectory:[[NSBundle mainBundle] bundlePath]];
	
	
	XLog(self, @"Task path: %@",taskPath);
	
	if (taskPath == nil) {
		return FALSE;
	}
	
	// Set launch path for task
	[task setLaunchPath:taskPath];
	
	// Before launching the task, get a filehandle for reading its output
	 NSFileHandle *readHandle = [[task standardOutput] fileHandleForReading];
	
	// Launch task
	[task launch];
	
	// Read output data
	NSData *readData;
	readData = [readHandle readDataToEndOfFile];
	NSString *readString = [[NSString alloc] initWithData:readData encoding:NSASCIIStringEncoding];
	
	XLog(self, @"Task said: %@", readString);
		
	// Notify opening callback selector on object
	[object performSelector:selector withObject:readString];
	
	[task release];
	
	return TRUE;
	
}

- (void)dealloc {
	if (rlSrc)
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
	if (dynStore)
		CFRelease(dynStore);
	if (airportStatus)
		CFRelease(airportStatus);
	
	[super dealloc];
}

@end
