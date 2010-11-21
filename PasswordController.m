//
//  PasswordController.m
//	Sidestep
//
//  Created by Ira Cooke on 27/07/2009. Modified with permission by Chetan Surpur.
//  Copyright 2009 Mudflat Software. 
//

#import "PasswordController.h"

@implementation PasswordController

/*
 *	Prompts the user for a password.
 *
 *	returns: array - {password, error code, save in keychain?}
 */

+ (NSArray *) promptForPassword:(NSString*)hostname user:(NSString*) username {
	CFUserNotificationRef passwordDialog;
	SInt32 error;
	CFOptionFlags responseFlags;
	int button;
	CFStringRef passwordRef;
	bool saveToKeychain;
	
	NSMutableArray *returnArray = [NSMutableArray arrayWithObjects:@"PasswordString",[NSNumber numberWithInt:0], [NSNumber numberWithBool:TRUE], nil];
	
	NSString *passwordMessageString = [NSString stringWithFormat:@"Please enter your password for %@@%@.",
									   username,
									   hostname];
	
	NSDictionary *panelDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Sidestep: Connecting to your secure server...",
							   kCFUserNotificationAlertHeaderKey,passwordMessageString,kCFUserNotificationAlertMessageKey,
							   @"Password:",kCFUserNotificationTextFieldTitlesKey,
							   @"Save in Keychain",kCFUserNotificationCheckBoxTitlesKey,
							   @"Cancel",kCFUserNotificationAlternateButtonTitleKey,
							   nil];
	
	passwordDialog = CFUserNotificationCreate(kCFAllocatorDefault,
											  0,
											  kCFUserNotificationPlainAlertLevel
											  |
											  CFUserNotificationSecureTextField(0),
											  &error,
											  (CFDictionaryRef)panelDict);
	
	
	if (error){
		// There was an error creating the password dialog
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:error]];
		return returnArray;
	}
	
	error = CFUserNotificationReceiveResponse(passwordDialog,
											  0,
											  &responseFlags);

	if (error){
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:error]];
		return returnArray;
	}
	
	
	button = responseFlags & 0x3;
	if (button == kCFUserNotificationAlternateResponse) {
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:1]];
		return returnArray;		
	}
	
	passwordRef = CFUserNotificationGetResponseValue(passwordDialog,
													 kCFUserNotificationTextFieldValuesKey,
													 0);
	
	saveToKeychain = responseFlags & CFUserNotificationCheckBoxChecked(0);

	[returnArray replaceObjectAtIndex:0 withObject:(NSString*)passwordRef];
	[returnArray replaceObjectAtIndex:2 withObject:[NSNumber numberWithBool:saveToKeychain]];

	CFRelease(passwordDialog); // Note that this will release the passwordRef as well
	
	return returnArray;	
}

/*
 *	Looks for the keychain entry corresponding to a username and hostname.
 *
 *	returns: password string if found
 *	returns: nil if password not found or username or hostname is nil
 */

+ (NSString*) passwordForHost:(NSString*)hostname user:(NSString*) username {
	if ( hostname == nil || username == nil ){
		return nil;
	}
	
	// Grab the keychain item
	EMInternetKeychainItem *keychainItem = [EMInternetKeychainItem internetKeychainItemForServer	:hostname
																						withUsername:username
																								path:@""
																								port:0
																							protocol:kSecProtocolTypeSSH];

	if (keychainItem) {
		return [keychainItem password];
	}
	else {
		return nil;
	}
	
}

/*
 *	Sets the password for the keychain entry corresponding to a username and hostname.
 *
 *	If the username/hostname combo already has an entry in the keychain then change it.
 *	If not then add a new entry.
 *
 *	returns: true if success
 *	returns: false if username or hostname is nil
 */

+ (BOOL) setPassword:(NSString*)newPassword forHost:(NSString*)hostname user:(NSString*) username {
	
	if ( hostname == nil || username == nil ){
		return FALSE;
	}
	
	// Grab the keychain item
	EMInternetKeychainItem *keychainItem = [EMInternetKeychainItem internetKeychainItemForServer	:hostname
																						withUsername:username
																								path:@""
																								port:0
																							protocol:kSecProtocolTypeSSH];
	
	if (keychainItem) {
		// The keychain item already exists but it needs to be updated
		[keychainItem setPassword:newPassword];
	}
	else {
		// The keychain item needs to be added
		[EMInternetKeychainItem addInternetKeychainItemForServer	:hostname
														withUsername:username
															password:newPassword
																path:@""
																port:0
															protocol:kSecProtocolTypeSSH];
	}
	
	return TRUE;
	
}

/*
 *	Deletes the keychain entry corresponding to a username and hostname.
 *
 *	returns: true if success
 *	returns: false if username or hostname is nil or entry doesn't exist
 */

+ (BOOL) deleteKeychainEntryForHost:(NSString*)hostname user:(NSString*) username {
	
	if ( hostname == nil || username == nil ){
		return FALSE;
	}
	
	// Grab the keychain item
	EMInternetKeychainItem *keychainItem = [EMInternetKeychainItem internetKeychainItemForServer	:hostname
																						withUsername:username
																								path:@""
																								port:0
																							protocol:kSecProtocolTypeSSH];
	
	if (keychainItem) {
		[keychainItem removeFromKeychain];
		
		return TRUE;
	}
	else {
		return FALSE;
	}
	
}

@end
