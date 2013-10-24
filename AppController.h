//
//  SidestepAppDelegate.h
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/SUUpdater.h>
#import "SSHConnector.h"
#import "DefaultsController.h"
#import "LoginItemController.h"
#import "NetworkNotifier.h"
#import "ProxySetter.h"
#import "VPNInterfacer.h"
#import "PasswordController.h"
#import "AppUtilities.h"
#import "GrowlMessage.h"

@interface AppController : NSObject <GrowlApplicationBridgeDelegate, NSTextFieldDelegate> { //<NSApplicationDelegate> {
    NSWindow *window;
	
	IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
	
	NSImage *statusImageDirectInsecure;
	NSImage *statusImageDirectSecure;
	NSImage *statusImageReroutedSecure;
	
	IBOutlet NSWindow *preferencesWindow;
	IBOutlet NSTabView *proxyTabs;
	
	IBOutlet NSWindow *welcomeWindow;
	IBOutlet NSTabView *welcomeTabs;
	
	IBOutlet NSMenuItem *proxyServerStatus;
	IBOutlet NSMenuItem *connectionStatus;
	
	IBOutlet NSMenuItem *rerouteOrRestoreConnectionButton;
	IBOutlet NSMenuItem *statusMenuFirstSeparator;
	IBOutlet NSMenuItem *connectVPNServiceButton;
	IBOutlet NSMenuItem *disconnectVPNServiceButton;
	
	SSHConnector *SSHconnector;
	DefaultsController *defaultsController;
	NetworkNotifier *networkNotifier;
	ProxySetter *proxySetter;
	VPNInterfacer *vpnInterfacer;
	
	GrowlMessage *growl;
	
	Boolean initiatedDelayedConnectionAttempt;
	int currentDelay;
	int retryCounter;
	
	Boolean testingConnection;
	IBOutlet NSTextField *testConnectionStatusField;
	
	IBOutlet NSTextField *testConnectionStatusFieldInPreferences;
	IBOutlet NSTextField *testConnectionStatusFieldInWelcome;
	
	IBOutlet NSPopUpButton *availableVPNServices;
	
	IBOutlet NSTextField *sshCommandDisplayField;
	
	NSTask *SSHConnection;
	Boolean SSHConnecting;
	Boolean SSHConnected;
	
	NSString *currentNetworkSecurityType;
    
    BOOL lion; //OSX version (important to choose "Airport" vs "Wi-Fi")
}

- (void)openSSHConnectionAfterDelay :(int)delay;
- (void)testSSHConnection;
- (void)closeSSHConnection;
- (void)openVPNConnectionAfterDelay :(int)delay;
- (void)closeVPNConnection;
- (void)setRunOnLogin :(BOOL)value;

- (void)showAuthorizationErrorSidestepDialog;
- (void)showRestartSidestepDialog;

- (void)updateUIForVPNServiceList;
- (void)updateUIForSelectedProxy;

- (void)preferencesClicked :(id)sender;
- (void)aboutClicked :(id)sender;
- (void)rerouteOrRestoreConnectionClicked :(id)sender;
- (void)testSSHConnectionClickedFromPreferences :(id)sender;
- (void)testSSHConnectionClickedFromWelcome :(id)sender;
- (void)helpWithProxyClicked :(id)sender;
- (void)nextClickedInWelcome :(id)sender;
- (void)finishClickedInWelcome :(id)sender;
- (void)toggleRunOnLoginClicked :(id)sender;
- (void)selectProxyClicked :(id)sender;
- (void)connectProxyClicked :(id)sender;
- (void)disconnectProxyClicked :(id)sender;

- (IBAction)compressionToggled:(id)sender;
- (NSString *)sshCommand;

- (NSDictionary *) registrationDictionaryForGrowl;

@end
