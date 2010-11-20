//
//  AppController.m
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import "AppController.h"

@implementation AppController

/*	
 *	Constants
 *******************************************************************************
 */

NSString *noNetworkConnectionStatusText				= @"Not connected to the Internet";
NSString *determiningConnectionStatusText			= @"Determining connection status...";
NSString *connectingConnectionStatusText			= @"Connecting to proxy server...";
NSString *retryingConnectionStatusText				= @"Retrying connection to proxy server...";
NSString *proxyConnectedConnectionStatusText		= @"Connection secured - rerouting traffic through proxy server";
NSString *protectedConnectionStatusText				= @"Connection secured - using encrypted direct wireless connection";
NSString *openConnectionStatusText					= @"(!) Connection insecure";

NSString *notConnectedServerStatusText				= @"Not connected to proxy server";
NSString *authorizationErrorServerStatusText		= @"Failed to reroute traffic - authorization failed";
NSString *connectionErrorServerStatusText			= @"Failed to reroute traffic - unable to reach server";
NSString *connectedServerStatusText					= @"Connected to proxy server";

NSString *testingConnectionStatusText				= @"Testing connection to server...";
NSString *authFailedTestingConnectionStatusText		= @"Failed connecting to server - authorization failed.";
NSString *reachFailedTestingConnectionStatusText	= @"Failed connecting to server - unable to reach server.";
NSString *sucessTestingConnectionStatusText			= @"Connection to server succeeded!";

NSString *rerouteConnectionButtonTitle				= @"Reroute Traffic Through Proxy Server Now";
NSString *restoreConnectionButtonTitle				= @"Restore Direct Internet Connection";

/*	
 *	Class methods
 *******************************************************************************
 */

- (id)init {
	
	self = [super init];
	
    if (self != nil)
    {
		SSHconnector = [[SSHConnector alloc] init];
		defaultsController = [[DefaultsController alloc] init];
		networkNotifier = [[NetworkNotifier alloc] init];
		proxySetter = [[ProxySetter alloc] init];
		
		initiatedDelayedConnectionAttempt = FALSE;
		currentDelay = 0;
		retryCounter = 0;
		
		SSHConnection = nil;
		SSHConnecting = FALSE;
		SSHConnected = FALSE;
		
		currentNetworkSecurityType = nil;
    }
	
    return self;	
	
}

- (void)dealloc {
	
	[SSHconnector release];
	[defaultsController release];
	[networkNotifier release];
	[proxySetter release];
	
	[statusImageDirectInsecure release];
	[statusImageDirectSecure release];
	[statusImageReroutedSecure release];

	[super dealloc];
	
}

/*
 *	UI Event Handlers
 *******************************************************************************
 */

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	int previousPID = [defaultsController getSSHConnectionPID];
	
	if (previousPID != 0) {
		XLog(self, @"Turning proxy off");
		
		[NSThread detachNewThreadSelector:@selector(turnProxyOffThread)
								 toTarget:self
							   withObject:nil];
		
		// Terminate previous SSH connection attempt if still running
		[NSThread detachNewThreadSelector:@selector(terminateSSHConnectionAttemptThread)
								 toTarget:self
							   withObject:nil];
		
		// Kill previous SSH connection
		[SSHconnector killSSHConnectionForPID:previousPID];
		
	}
	
	[networkNotifier listenForAirportConnectionAndNotifyObject:self
												  withSelector:@selector(connectedToAirportNetwork)];
	
	// Check if current network type is insecure
	[networkNotifier getNetworkSecurityTypeAndNotifyObject:self withSelector:@selector(connectedToAirportNetworkWithSecurityType:)];
	
}

- (void)awakeFromNib {
	
	// Create status menu item
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setMenu:statusMenu];
	[statusItem setHighlightMode:YES];
	
	// Used to detect where our files are
	NSBundle *bundle = [NSBundle mainBundle];
	
	// Allocates and loads the images into the application which will be used for our NSStatusItem
	statusImageDirectInsecure = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"direct-insecure-icon" ofType:@"png"]];
	statusImageDirectSecure = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"direct-secure-icon" ofType:@"png"]];
	statusImageReroutedSecure = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"rerouted-secure-icon" ofType:@"png"]];
	
	// Sets the default images in our NSStatusItem
	[statusItem setImage:statusImageDirectSecure];
	[statusItem setAlternateImage:statusImageDirectSecure];
	
	// Set first-run default preferences
	if (![defaultsController ranAtleastOnce]) {
	
		[defaultsController setRerouteAutomatically:TRUE];
		[defaultsController setRanAtleastOnce:TRUE];
		
		[defaultsController setRunOnLogin:TRUE];
		[self setRunOnLogin:TRUE];
		
		// Show welcome window
		[welcomeWindow center];
		[welcomeTabs selectFirstTabViewItem:self];
		[welcomeWindow setIsVisible:TRUE];
		[welcomeWindow makeKeyAndOrderFront:self];
		
	}
	
	// Update connection status
	[connectionStatus setTitle:determiningConnectionStatusText];
	
	// Update proxy server status
	[proxyServerStatus setTitle:notConnectedServerStatusText];
	
	// Set reroute or restore button title
	[rerouteOrRestoreConnectionButton setTitle:rerouteConnectionButtonTitle];
	
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	
	XLog(self, @"User clicked Quit");
	
	if (SSHConnecting || SSHConnected) {
		[NSApp activateIgnoringOtherApps:YES];	// Allows windows of this app to become front
		
		// Ask if user really wants to quit
		int decision = NSRunCriticalAlertPanel (@"Do you want to restore a direct Internet connection before you quit?",
												@"If you quit without restoring a direct Internet connection, your connection "
												"will continue to be routed through the secure connection to your proxy server. "
												"To manage the connection again, just restart Sidestep.",
												@"Yes",
												@"No",
												nil,
												nil);
		
		// Operate based on user's decision
		if (decision == NSAlertDefaultReturn) {	// Answer was "Yes"
			XLog(self, @"Turning proxy off");
			[NSThread detachNewThreadSelector:@selector(turnProxyOffThread)
									 toTarget:self
								   withObject:nil];
			
			if (SSHConnection) {
				XLog(self, @"Killing current SSH connection");
				[SSHConnection terminate];
			}
			
			XLog(self, @"Terminating current SSH connection attempt");
			[NSThread detachNewThreadSelector:@selector(terminateSSHConnectionAttemptThread)
									 toTarget:self
								   withObject:nil];
		}
	}
	
	return NSTerminateNow;
	
}

/*
 *	Functions
 *******************************************************************************
 */

- (void)openSSHConnectionAfterDelay :(int)delay {
	
	if (!SSHConnected || testingConnection) {
		if (SSHConnecting) {
			if (SSHConnection) {
				XLog(self, @"Killing current SSH connection");
				[SSHConnection terminate];
			}
			
			XLog(self, @"Terminating current SSH connection attempt");
			[NSThread detachNewThreadSelector:@selector(terminateSSHConnectionAttemptThread)
									 toTarget:self
								   withObject:nil];
			
			SSHConnecting = FALSE;
		}
		
		// Reset current delay
		currentDelay = delay;
		
		// Reset retry counter
		retryCounter = 0;
		
		// Initiate connection attempt after delay if not already initiated
		if (!initiatedDelayedConnectionAttempt && !SSHConnecting) {			
			XLog(self, @"Opening new SSH connection after delay");
			
			initiatedDelayedConnectionAttempt = TRUE;
			
			[NSThread detachNewThreadSelector:@selector(openSSHConnectionAfterDelayThread)
									 toTarget:self
								   withObject:nil];
		}
	}
	
}

- (void)testSSHConnection {
	
	testingConnection = TRUE;
	
	[self openSSHConnectionAfterDelay:0];
	
}

- (void)closeSSHConnection {
	
	if (SSHConnection) {
		XLog(self, @"Turning proxy off");
		[NSThread detachNewThreadSelector:@selector(turnProxyOffThread)
								 toTarget:self
							   withObject:nil];
		
		XLog(self, @"Killing current SSH connection");
		[SSHConnection terminate];
	}
	
	if (SSHConnecting) {
		XLog(self, @"Terminating current SSH connection attempt");
		[NSThread detachNewThreadSelector:@selector(terminateSSHConnectionAttemptThread)
								 toTarget:self
							   withObject:nil];
	}
	
	SSHConnecting = FALSE;		
	SSHConnected = FALSE;	
	
}

- (void)setRunOnLogin :(BOOL)value {
	
	[self willChangeValueForKey:@"startAtLogin"];
	
	NSURL *appURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	
	if (value) {
		XLog(self, @"Enabling run on login");
		
		[LoginItemController setStartAtLogin:appURL enabled:TRUE];		
	}
	else {
		XLog(self, @"Disabling run on login");
		
		[LoginItemController setStartAtLogin:appURL enabled:FALSE];
	}
	
	[self didChangeValueForKey:@"startAtLogin"];
	
}

/*
 *	Threads
 *******************************************************************************
 */

- (void)openSSHConnectionAfterDelayThread {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	while (currentDelay > 0) {
		XLog(self, @"Opening SSH connection in %d seconds", currentDelay);
		
		// Sleep for one second
		NSDate *future = [NSDate dateWithTimeIntervalSinceNow:1];
		[NSThread sleepUntilDate:future];
		
		// Decrement current delay
		currentDelay--;
	}
	
	NSString *username = [defaultsController getServerUsername];
	NSString *hostname = [defaultsController getServerHostname];
	
	if (username && hostname) {	
		[SSHconnector openSSHConnectionAndNotifyObject:self
								   withOpeningSelector:@selector(SSHConnectionOpening:)
								   withSuccessSelector:@selector(SSHConnectionOpened:)
								   withFailureSelector:@selector(SSHConnectionFailed:)
										  withUsername:username
										  withHostname:hostname
									 withLocalBindPort:[NSNumber numberWithInt:9050]];
	}
	else {
		XLog(self, @"No username or hostname found");
	}
	
	initiatedDelayedConnectionAttempt = FALSE;
	
	[pool release];
}

- (void)watchSSHConnectionForCloseThread :(NSTask *)connection {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  
    
    [SSHconnector watchSSHConnectionAndOnCloseNotifyObject:self
											  withSelector:@selector(SSHConnectionClosed)
											withConnection:connection];
	
	[pool release];
    
}

- (void)terminateSSHConnectionAttemptThread {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[SSHconnector terminateSSHConnectionAttempt];
	
	[pool release];

}

- (void)turnProxyOnThread :(NSNumber *)port {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
	[proxySetter turnProxyOn:port];
	
	[pool release];
}

- (void)turnProxyOffThread {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[proxySetter turnProxyOff];
	
	[pool release];
}

/*
 *	Event handlers
 *******************************************************************************
 */

- (void)SSHConnectionOpening :(NSTask *)connection {
	
	XLog(self, @"Called SSHConnectionOpening. Connection task PID: %d", [connection processIdentifier]);
	
	[defaultsController saveSSHConnectionPID:[connection processIdentifier]];
	
	if (testingConnection) {
		[self performSelectorOnMainThread:@selector(updateUIForTestingSSHConnectionOpening) withObject:nil waitUntilDone:FALSE];
	}
	else {
		[self performSelectorOnMainThread:@selector(updateUIForSSHConnectionOpening) withObject:nil waitUntilDone:FALSE];
	}
	
	[NSThread detachNewThreadSelector:@selector(watchSSHConnectionForCloseThread:)
							 toTarget:self
						   withObject:connection];
	
	SSHConnection = connection;
	SSHConnecting = TRUE;
	
}

- (void)SSHConnectionOpened :(NSTask *)connection {
	
    XLog(self, @"Called SSHConnectionOpened. Connection task PID: %d", [connection processIdentifier]);

	SSHConnected = TRUE;
	SSHConnecting = FALSE;
	
	if (testingConnection) {
		if (SSHConnection) {
			XLog(self, @"Killing current SSH connection");
			[SSHConnection terminate];
		}
		
		XLog(self, @"Terminating current SSH connection attempt");
		[NSThread detachNewThreadSelector:@selector(terminateSSHConnectionAttemptThread)
								 toTarget:self
							   withObject:nil];
	
		testingConnection = FALSE;
		
		[self performSelectorOnMainThread:@selector(updateUIForTestingSSHConnectionSucceeded) withObject:nil waitUntilDone:FALSE];
	}
	else {
		XLog(self, @"Turning proxy on");
		[NSThread detachNewThreadSelector:@selector(turnProxyOnThread:)
								 toTarget:self
							   withObject:[NSNumber numberWithInt:9050]];
		
		[self performSelectorOnMainThread:@selector(updateUIForSSHConnectionOpened) withObject:nil waitUntilDone:FALSE];
	}
	
}

- (void)SSHConnectionFailed :(NSString *)errorCode {
	
    XLog(self, @"Called SSHConnectionFailed.");
	
	SSHConnection = nil;
	SSHConnected = FALSE;
	SSHConnecting = FALSE;
	
	if (testingConnection) {
		testingConnection = FALSE;
		
		[self performSelectorOnMainThread:@selector(updateUIForTestingSSHConnectionFailedWithError:) withObject:errorCode waitUntilDone:FALSE];
	}
	else {
		[self performSelectorOnMainThread:@selector(updateUIForSSHConnectionFailedWithError:) withObject:errorCode waitUntilDone:FALSE];
		
		if (![errorCode isEqualToString:@"2"] && ![errorCode isEqualToString:@"5"] && retryCounter < 2) {
			XLog(self, @"Retrying connection attempt after delay. Retry counter: %d", retryCounter);
			
			[self performSelectorOnMainThread:@selector(updateUIForSSHConnectionRetrying) withObject:nil waitUntilDone:FALSE];
			
			currentDelay = 3;
			initiatedDelayedConnectionAttempt = TRUE;
			
			[NSThread detachNewThreadSelector:@selector(openSSHConnectionAfterDelayThread)
									 toTarget:self
								   withObject:nil];
			
			retryCounter++;
		}
		else if (retryCounter >= 2) {
			[self performSelectorOnMainThread:@selector(updateConnectionStatusForCurrentNetwork) withObject:nil waitUntilDone:FALSE];
		}
	}
	
}

- (void)SSHConnectionClosed {

    XLog(self, @"SSH Connection was closed.");
	
	if (SSHConnecting) {	// Connection was closed while connecting before SSH connection watcher started
		// Terminate current SSH connection attempt if still running
		[NSThread detachNewThreadSelector:@selector(terminateSSHConnectionAttemptThread)
								 toTarget:self
							   withObject:nil];
	}
	
	if (SSHConnected) {
		XLog(self, @"Turning proxy off");
		[NSThread detachNewThreadSelector:@selector(turnProxyOffThread)
								 toTarget:self
							   withObject:nil];
	}
	
	if (!testingConnection) {
		[self performSelectorOnMainThread:@selector(updateUIForSSHConnectionClosed) withObject:nil waitUntilDone:FALSE];
	}
	
	SSHConnection = nil;
	SSHConnected = FALSE;
	SSHConnecting = FALSE;

}

- (void)connectedToAirportNetwork {
	
	[networkNotifier getNetworkSecurityTypeAndNotifyObject:self withSelector:@selector(connectedToAirportNetworkWithSecurityType:)];
	
}

- (void)connectedToAirportNetworkWithSecurityType:(NSString *)security {
	
	XLog(self, @"Network security type: %@", security);
	
	currentNetworkSecurityType = security;
	
	[self performSelectorOnMainThread:@selector(updateConnectionStatusForCurrentNetwork) withObject:nil waitUntilDone:FALSE];
	
	if ([security isEqualToString:@"none"] && [defaultsController rerouteAutomaticallyEnabled]) {
		[self openSSHConnectionAfterDelay:3];
	}
	else {		
		[self closeSSHConnection];
	}

}

/*
 *	UI Functions
 *******************************************************************************
 */

- (void)updateConnectionStatusForCurrentNetwork {
	XLog(self, @"Called updateConnectionStatusForCurrentNetwork");
	
	if ([currentNetworkSecurityType isEqualToString:@""]) {
		[connectionStatus setTitle:noNetworkConnectionStatusText];
		
		// Update the images in our NSStatusItem
		[statusItem setImage:statusImageDirectSecure];
		[statusItem setAlternateImage:statusImageDirectSecure];
	}
	else if ([currentNetworkSecurityType isEqualToString:@"none"]) {
		[connectionStatus setTitle:openConnectionStatusText];
		
		// Update the images in our NSStatusItem
		[statusItem setImage:statusImageDirectInsecure];
		[statusItem setAlternateImage:statusImageDirectInsecure];
	}
	else {
		[connectionStatus setTitle:protectedConnectionStatusText];
		
		// Update the images in our NSStatusItem
		[statusItem setImage:statusImageDirectSecure];
		[statusItem setAlternateImage:statusImageDirectSecure];
	}
	
}
														
- (void)updateUIForSSHConnectionRetrying {
	XLog(self, @"Called updateUIForSSHConnectionRetrying");
	
	// Update connection status
	[connectionStatus setTitle:retryingConnectionStatusText];
	
}

- (void)updateUIForSSHConnectionOpening {
	XLog(self, @"Called updateUIForSSHConnectionOpening");
	
	// Update connection status
	[connectionStatus setTitle:connectingConnectionStatusText];
	
	// Disable reroute or restore button
	[rerouteOrRestoreConnectionButton setEnabled:FALSE];

}

- (void)updateUIForSSHConnectionOpened {
	XLog(self, @"Called updateUIForSSHConnectionOpened");
	
	// Update connection status
	[connectionStatus setTitle:proxyConnectedConnectionStatusText];
	
	// Update proxy server status
	[proxyServerStatus setTitle:connectedServerStatusText];
	
	// Set reroute or restore button title
	[rerouteOrRestoreConnectionButton setTitle:restoreConnectionButtonTitle];
	
	// Enable reroute or restore button
	[rerouteOrRestoreConnectionButton setEnabled:TRUE];
	
	// Update the images in our NSStatusItem
	[statusItem setImage:statusImageReroutedSecure];
	[statusItem setAlternateImage:statusImageReroutedSecure];
}

- (void)updateUIForSSHConnectionFailedWithError :(NSString *)errorCode {
	XLog(self, @"Called updateUIForSSHConnectionFailedWithError");
	
	if ([errorCode isEqualToString:@"2"]) {
		// Update proxy server status
		[proxyServerStatus setTitle:authorizationErrorServerStatusText];
	}
	else if ([errorCode isEqualToString:@"3"] || [errorCode isEqualToString:@"4"]) {
		// Update proxy server status
		[proxyServerStatus setTitle:connectionErrorServerStatusText];
	}
	
	// Update connection status
	[self updateConnectionStatusForCurrentNetwork];
	
	// Set reroute or restore button title
	[rerouteOrRestoreConnectionButton setTitle:rerouteConnectionButtonTitle];
	
	// Enable reroute or restore button
	[rerouteOrRestoreConnectionButton setEnabled:TRUE];
	
}

- (void)updateUIForSSHConnectionClosed {
	XLog(self, @"Called updateUIForSSHConnectionClosed");

	// Update connection status
	[self updateConnectionStatusForCurrentNetwork];
	
	// Update proxy server status
	[proxyServerStatus setTitle:notConnectedServerStatusText];
	
	// Update reroute or restore button title
	[rerouteOrRestoreConnectionButton setTitle:rerouteConnectionButtonTitle];
	
}

- (void)updateUIForTestingSSHConnectionOpening {
	XLog(self, @"Called updateUIForTestingSSHConnectionOpening");
	
	// Update testing connection status
	[testConnectionStatusField setStringValue:testingConnectionStatusText];
	
}

- (void)updateUIForTestingSSHConnectionSucceeded {
	XLog(self, @"Called updateUIForTestingSSHConnectionSucceeded");
	
	// Update testing connection status
	[testConnectionStatusField setStringValue:sucessTestingConnectionStatusText];
	
}

- (void)updateUIForTestingSSHConnectionFailedWithError :(NSString *)errorCode {
	XLog(self, @"Called updateUIForTestingSSHConnectionFailedWithError");
	
	if ([errorCode isEqualToString:@"2"]) {
		// Update testing connection status
		[testConnectionStatusField setStringValue:authFailedTestingConnectionStatusText];
	}
	else if ([errorCode isEqualToString:@"3"] || [errorCode isEqualToString:@"4"] || [errorCode isEqualToString:@"5"]) {
		// Update testing connection status
		[testConnectionStatusField setStringValue:reachFailedTestingConnectionStatusText];
	}
	
}

/*
 *	UI Receivers
 *******************************************************************************
 */


- (void)preferencesClicked :(id)sender {
	
	[NSApp activateIgnoringOtherApps:YES];	// Allows windows of this app to become front
	
	[preferencesWindow center];
	[preferencesWindow setIsVisible:TRUE];
	[preferencesWindow makeKeyAndOrderFront:self];
	
}

- (void)aboutClicked :(id)sender {
	
	[NSApp activateIgnoringOtherApps:YES];	// Allows windows of this app to become front
	
	[welcomeWindow center];
	[welcomeTabs selectFirstTabViewItem:self];
	[welcomeWindow setIsVisible:TRUE];
	[welcomeWindow makeKeyAndOrderFront:self];
	
}

- (void)rerouteOrRestoreConnectionClicked :(id)sender {
	
	if ([[rerouteOrRestoreConnectionButton title] isEqualToString:rerouteConnectionButtonTitle]) {
		XLog(self, @"Reroute connection button clicked");
		
		[self openSSHConnectionAfterDelay:0];
	}
	else if ([[rerouteOrRestoreConnectionButton title] isEqualToString:restoreConnectionButtonTitle]) {
		XLog(self, @"Restore connection button clicked");
		
		[self closeSSHConnection];
	}
	
}

- (void)testSSHConnectionClickedFromPreferences :(id)sender {

	// Update test connection status
	testConnectionStatusField = testConnectionStatusFieldInPreferences;
	
	// Bring focus to button
	[preferencesWindow makeFirstResponder:sender];
	
	[self testSSHConnection];
	
}

- (void)testSSHConnectionClickedFromWelcome :(id)sender {
	
	// Update test connection status
	testConnectionStatusField = testConnectionStatusFieldInWelcome;
	
	// Bring focus to button
	[welcomeWindow makeFirstResponder:sender];
	
	[self testSSHConnection];
	
}

- (void)helpWithProxyClicked :(id)sender {

	
	
}

- (void)nextClickedInWelcome :(id)sender {
	
	[welcomeTabs selectNextTabViewItem:self];
	
}

- (void)finishClickedInWelcome :(id)sender {
	
	[welcomeWindow setIsVisible:FALSE];
	
}

- (void)toggleRunOnLoginClicked :(id)sender {
	
	// [defaultsController runOnLogin] will now return updated value of the run on login checkbox
	
	[self setRunOnLogin:[defaultsController runOnLogin]];
	
}

@end
