//
//  LoginItemController.h
//  Sidestep
//
//	From GrowlPreferencesController.h
//  Growl
//
//  Created by Nelson Elhage on 8/24/04. Modified by Chetan Surpur on 11/19/10.
//  Renamed from GrowlPreferences.m by Mac-arena the Bored Zo on 2005-06-27.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>


@interface LoginItemController : NSObject {

}

+ (BOOL) willStartAtLogin:(NSURL *)itemURL;
+ (void) setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled;

@end
