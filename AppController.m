//
//  AppController.m
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import "AppController.h"
#import "GrowlMessage.h"
@implementation AppController

/*	
 *	Constants
 *******************************************************************************
 */

NSString *noNetworkConnectionStatusText				= @"No wireless connection found";
NSString *determiningConnectionStatusText			= @"Determining connection status...";
NSString *connectingConnectionStatusText			= @"Connecting to proxy server...";
NSString *retryingConnectionStatusText				= @"Retrying connection to proxy server...";
NSString *proxyConnectedConnectionStatusText		= @"Connection secured - rerouting traffic through proxy server";
NSString *protectedConnectionStatusText				= @"Connection secured - using encrypted direct wireless connection";
NSString *openConnectionStatusText					= @"Unsecured network connection";

NSString *notConnectedServerStatusText				= @"Not connected to proxy server";
NSString *authorizationErrorServerStatusText		= @"Failed to reroute traffic - authorization failed";
NSString *connectionErrorServerStatusText			= @"Failed to reroute traffic - unable to reach server";
NSString *connectedServerStatusText					= @"Connected to proxy server";

NSString *connectedVPNText							= @"Connected to VPN service";
NSString *disconnectedVPNText						= @"Disconnected from VPN service";
NSString *unknownVPNText							= @"VPN service not found";
NSString *noVPNText									= @"No VPN service selected";

NSString *testingConnectionStatusText				= @"Testing connection to server...";
NSString *authFailedTestingConnectionStatusText		= @"Failed connecting to server - authorization failed.\n\n"
													   "Please click the Test Connection button again to retry "
													   "entering your password.";
NSString *reachFailedTestingConnectionStatusText	= @"Failed connecting to server - unable to reach server.";
NSString *sucessTestingConnectionStatusText			= @"Connection to server succeeded!";

NSString *restoredDirectConnectionStatusText		= @"Restored direct Internet connection.";

NSString *rerouteConnectionButtonTitle				= @"Reroute Traffic Through Proxy Server Now";
NSString *restoreConnectionButtonTitle				= @"Restore Direct Internet Connection";

NSString *helpWithProxyURL							= @"http://chetansurpur.com/projects/sidestep/#proxy-servers";

/* Growl spam reduction  
 *     Growl outputs 10 - 12 error messages simulatenously when connecting to an unsecured network.
 *     This hack only allows the notification to occur once.  
 */

NSInteger GrowlSpam_ConnectionType					= 0;
NSInteger GrowlSpam_ConnectingToProxy				= 0;
NSInteger GrowlSpam_TestConnection					= 0;

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
		vpnInterfacer = [[VPNInterfacer alloc] init];
		
		growl = [[GrowlMessage alloc] init];
		
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
	[vpnInterfacer release];
	
	[statusImageDirectInsecure release];
	[statusImageDirectSecure release];
	[statusImageReroutedSecure release];
	
	[growl release];
	
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
		
		[NSThread detachNewThreadSelector:@selector(turnWirelessProxyOffThread)
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
	if (![networkNotifier getNetworkSecurityTypeAndNotifyObject	:self
													withSelector:@selector(connectedToAirportNetworkWithSecurityType:)]) {
		[self showRestartSidestepDialog];
	}
	
}

- (void)awakeFromNib {
	
	// Set selected proxy if not already set
	if ([defaultsController selectedProxy] == nil || [defaultsController selectedProxy] == @"") {	
		[defaultsController setSelectedProxy:@"1"];
	}
	
	// Update VPN service lists
	[self updateUIForVPNServiceList];
	
	// Update UI for the selected proxy
	[self updateUIForSelectedProxy];
	
	// Growl
	[GrowlApplicationBridge setGrowlDelegate:self];
	
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
	
	// Check for updates if not first run and check for updates is enabled
	if ([defaultsController ranAtleastOnce] && [[SUUpdater sharedUpdater] automaticallyChecksForUpdates]) {
		XLog(self, @"Checking for updates");
		[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
	}
	
	// Set first-run default preferences
	if (![defaultsController ranAtleastOnce]) {
	
		[defaultsController setRerouteAutomatically:TRUE];
		[defaultsController setRanAtleastOnce:TRUE];
		
		[defaultsController setRunOnLogin:TRUE];
		[self setRunOnLogin:TRUE];
		
		[defaultsController setGrowlSetting:TRUE];
		
		// Show welcome window
		[welcomeWindow center];
		[welcomeTabs selectFirstTabViewItem:self];
		[welcomeWindow setIsVisible:TRUE];
		[welcomeWindow makeKeyAndOrderFront:self];
		
	}
	
    // Set default remote port number if not already set
    if ([defaultsController getRemotePortNumber] == nil || [defaultsController getRemotePortNumber] == @"") {
		[defaultsController setRemotePortNumber:@"22"];
    }
	
	// Enable Growl if preference is not found (user updated from previous version / has already completed 1st run)
    if (![defaultsController getGrowlSetting]) {
		[defaultsController setGrowlSetting:TRUE];
    }
	
	// Set default local port number if not already set
    if ([defaultsController getLocalPortNumber] == nil || [defaultsController getLocalPortNumber] == @"") {
		[defaultsController setLocalPortNumber:@"9050"];
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
			[NSThread detachNewThreadSelector:@selector(turnWirelessProxyOffThread)
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
		[NSThread detachNewThreadSelector:@selector(turnWirelessProxyOffThread)
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
	
	/* Set process to 0.  
	 * Otherwise, next launch of Sidestep will read this variable and think it crashed.  
	 * Sidestep would then try to kill the PID stored the last time it ran, potentially killing an unintended process.
	 */
	[defaultsController saveSSHConnectionPID:0];
}

- (void)openVPNConnectionAfterDelay :(int)delay {
		
	// Reset current delay
	currentDelay = delay;
	
	// Initiate connection attempt after delay if not already initiated
	if (!initiatedDelayedConnectionAttempt) {			
		XLog(self, @"Opening VPN connection after delay");
		
		initiatedDelayedConnectionAttempt = TRUE;
		
		if (![[defaultsController selectedVPNService] isEqualToString:@"None"]) {
			[NSThread detachNewThreadSelector:@selector(openVPNConnectionAfterDelayThread)
									 toTarget:self
								   withObject:nil];
		}
		else {
			[growl message:noVPNText];
		}
	}
	
}

- (void)closeVPNConnection {
	
	XLog(self, @"Closing VPN connection");
	
	if (![[defaultsController selectedVPNService] isEqualToString:@"None"]) {
		[NSThread detachNewThreadSelector:@selector(closeVPNConnectionThread)
								 toTarget:self
							   withObject:nil];
	}
	else {
		[growl message:noVPNText];
	}
	
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
- (void)setGrowlSetting :(BOOL)value {
	if (value) {
		XLog(self, @"Enabling Growl Notification");
		[defaultsController setGrowlSetting:TRUE];
		[self setGrowlSetting:TRUE];
	}
	else {
		XLog(self, @"Disabling Growl Notification");
	}

}
 */

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *notifications;
	notifications = [NSArray arrayWithObject:@"GrowlNotification"];
	
	NSDictionary *dict;
	dict = [NSDictionary dictionaryWithObjectsAndKeys:
			notifications, GROWL_NOTIFICATIONS_ALL,
			notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
	
	return (dict);
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
	NSString *remoteport = [defaultsController getRemotePortNumber];
	NSNumber *localport = (NSNumber *)[defaultsController getLocalPortNumber];
	
	if (username && hostname) {	
		if (![SSHconnector openSSHConnectionAndNotifyObject:self
										withOpeningSelector:@selector(SSHConnectionOpening:)
										withSuccessSelector:@selector(SSHConnectionOpened:)
										withFailureSelector:@selector(SSHConnectionFailed:)
											   withUsername:username
											   withHostname:hostname
												withRemotePort:(NSString *)remoteport
										  withLocalBindPort:(NSNumber *)localport]) {
			[self showRestartSidestepDialog];
		}
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

- (void)turnWirelessProxyOnThread :(NSNumber *)port {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Snow Leopard
	if (![proxySetter turnAirportProxyOn:port]) {
		[self showRestartSidestepDialog];
	}
    
    // Lion
    if (![proxySetter turnWiFiProxyOn:port]) {
		[self showRestartSidestepDialog];
	}
	
	[pool release];
}

- (void)turnWirelessProxyOffThread {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    // Snow Leopard
    if (![proxySetter turnAirportProxyOff]) {
		[self showRestartSidestepDialog];
	}
    
    // Lion
    if (![proxySetter turnWiFiProxyOff]) {
		[self showRestartSidestepDialog];
	}
    
	[pool release];
}

- (void)openVPNConnectionAfterDelayThread {

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while (currentDelay > 0) {
		XLog(self, @"Opening VPN connection in %d seconds", currentDelay);
		
		// Sleep for one second
		NSDate *future = [NSDate dateWithTimeIntervalSinceNow:1];
		[NSThread sleepUntilDate:future];
		
		// Decrement current delay
		currentDelay--;
	}
	
	int result = [vpnInterfacer turnVPNOnOrOff:[defaultsController selectedVPNService] withState:TRUE];
	if (!result) {
		[self showRestartSidestepDialog];
	}
	else {
		if (result == 1) {
			[growl message:connectedVPNText];
		}
		else {
			[growl message:unknownVPNText];
		}
	}
	
	initiatedDelayedConnectionAttempt = FALSE;
	
	[pool release];
	
}

- (void)closeVPNConnectionThread {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	int result = [vpnInterfacer turnVPNOnOrOff:[defaultsController selectedVPNService] withState:FALSE];
	if (!result) {
		[self showRestartSidestepDialog];
	}
	else {
		if (result == 1) {
			[growl message:disconnectedVPNText];
		}
		else {
			[growl message:unknownVPNText];
		}
	}
	
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
		NSNumber *localport = (NSNumber *)[defaultsController getLocalPortNumber];
		
		[NSThread detachNewThreadSelector:@selector(turnWirelessProxyOnThread:)
								 toTarget:self
							   withObject:[NSNumber numberWithInt:[localport intValue]]];
		[self performSelectorOnMainThread:@selector(updateUIForSSHConnectionOpened) withObject:nil waitUntilDone:FALSE];
	}
	
}

- (void)SSHConnectionFailed :(NSString *)errorCode {
	
    XLog(self, @"Called SSHConnectionFailed.");
	
	SSHConnection = nil;
	SSHConnected = FALSE;
	SSHConnecting = FALSE;
	
	XLog(self, @"Resetting keychain entry");
	
	if ([errorCode isEqualToString:@"2"]) {
		BOOL result = [PasswordController deleteKeychainEntryForHost:[defaultsController getServerHostname] user:[defaultsController getServerUsername]];
		XLog(self, @"Result of trying to delete keychain entry: %d", result);
	}
	
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
		[NSThread detachNewThreadSelector:@selector(turnWirelessProxyOffThread)
								 toTarget:self
							   withObject:nil];
	}
	
	if (!testingConnection) {
		[self performSelectorOnMainThread:@selector(updateUIForSSHConnectionClosed) withObject:nil waitUntilDone:FALSE];
	}
	
	[growl message:restoredDirectConnectionStatusText];
	
	SSHConnection = nil;
	SSHConnected = FALSE;
	SSHConnecting = FALSE;

}

- (void)connectedToAirportNetwork {
	
	if (![networkNotifier getNetworkSecurityTypeAndNotifyObject	:self
													withSelector:@selector(connectedToAirportNetworkWithSecurityType:)]) {
		[self showRestartSidestepDialog];
	}
	
}

- (void)connectedToAirportNetworkWithSecurityType:(NSString *)security {
	
	XLog(self, @"Network security type: %@", security);
	
	currentNetworkSecurityType = security;
	
	[self performSelectorOnMainThread:@selector(updateConnectionStatusForCurrentNetwork) withObject:nil waitUntilDone:FALSE];
	
    /* Kill process if there's one running
     */
    if ([defaultsController getSSHConnectionPID] != 0) {
        [self closeSSHConnection];
    }
    if ([[defaultsController selectedProxy] isEqualToString:@"0"]) {
        [self closeVPNConnection];
    }
    
    /* Launch new process if needed
     */
	if ([security isEqualToString:@"none"] && [defaultsController rerouteAutomaticallyEnabled]) {
		if ([[defaultsController selectedProxy] isEqualToString:@"1"]) {
			[self openSSHConnectionAfterDelay:3];
		}
		else {
			[self openVPNConnectionAfterDelay:3];
		}
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
		
		if (GrowlSpam_ConnectionType != 1 && GrowlSpam_TestConnection != 1) {
			[growl message:noNetworkConnectionStatusText];
			GrowlSpam_ConnectionType = 1;
			GrowlSpam_TestConnection = 0;
		}
		// Update the images in our NSStatusItem
		[statusItem setImage:statusImageDirectSecure];
		[statusItem setAlternateImage:statusImageDirectSecure];
	}
	else if ([currentNetworkSecurityType isEqualToString:@"none"]) {
		[connectionStatus setTitle:openConnectionStatusText];
		if (GrowlSpam_ConnectionType != 2) {
			[growl message:openConnectionStatusText];
			GrowlSpam_ConnectionType = 2;
		}
		// Update the images in our NSStatusItem
		[statusItem setImage:statusImageDirectInsecure];
		[statusItem setAlternateImage:statusImageDirectInsecure];
	}
	else {
		[connectionStatus setTitle:protectedConnectionStatusText];
		if (GrowlSpam_ConnectionType != 3) {
			[growl message:protectedConnectionStatusText];
			GrowlSpam_ConnectionType = 3;
		}
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
	if (GrowlSpam_ConnectingToProxy == 0) {
		[growl message:connectingConnectionStatusText];
		GrowlSpam_ConnectingToProxy == 1;
	}
	
	// Disable reroute or restore button
	[rerouteOrRestoreConnectionButton setEnabled:FALSE];

}

- (void)updateUIForSSHConnectionOpened {
	
	XLog(self, @"Called updateUIForSSHConnectionOpened");
	
	// Update connection status
	[connectionStatus setTitle:proxyConnectedConnectionStatusText];
	[growl message:proxyConnectedConnectionStatusText];
	
	// Reset GrowlSpam variable to allow notifications now that spam should have ended
	GrowlSpam_ConnectingToProxy == 0;
	
	// Update proxy server status
	// Proxy server status is updated in another growl message.  No need to add one here.
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
	[growl message:testingConnectionStatusText];
	
	// Prevent wireless status from appearing after test.
	GrowlSpam_TestConnection = 1;
	
}

- (void)updateUIForTestingSSHConnectionSucceeded {
	
	XLog(self, @"Called updateUIForTestingSSHConnectionSucceeded");
	
	// Update testing connection status
	[testConnectionStatusField setStringValue:sucessTestingConnectionStatusText];
	[growl message:sucessTestingConnectionStatusText];
	
	// Growl Spam Reduction reset.  This allows messages to appear if the user connects to a different network of the same type.
	GrowlSpam_ConnectionType = 0;
		
}

- (void)updateUIForTestingSSHConnectionFailedWithError :(NSString *)errorCode {
	
	XLog(self, @"Called updateUIForTestingSSHConnectionFailedWithError");
	
	if ([errorCode isEqualToString:@"2"]) {
		// Update testing connection status
		[testConnectionStatusField setStringValue:authFailedTestingConnectionStatusText];
		[growl message:authFailedTestingConnectionStatusText];
		
	}
	else if ([errorCode isEqualToString:@"3"] || [errorCode isEqualToString:@"4"] || [errorCode isEqualToString:@"5"]) {
		// Update testing connection status
		[testConnectionStatusField setStringValue:reachFailedTestingConnectionStatusText];
		[growl message:reachFailedTestingConnectionStatusText];
		
	}
	
	// Growl Spam Reduction reset.  This allows messages to appear if the user connects to a different network of the same type.
	GrowlSpam_ConnectionType = 0;
	
}

- (void)showRestartSidestepDialog {
	
	XLog(self, @"Showing user restart Sidestep dialog");
	
	[NSApp activateIgnoringOtherApps:YES];	// Allows windows of this app to become front
	
	NSRunCriticalAlertPanel(	@"Please restart Sidestep",
								@"It seems that you've moved Sidestep to somewhere else on your computer "
								 "or have renamed the application.\n\n"
								 "Please close and open Sidestep again in order to ensure smooth running.\n\n"
								 "Until you do so, you might experience problems with Sidestep and your "
								 "Internet connection.",
								@"OK",
								nil,
								nil,
								nil);
	
}

- (void)updateUIForVPNServiceList {
	
	XLog(self, @"Currently selected VPN service: %@", [defaultsController selectedVPNService]);
	
	XLog(self, @"Updating UI for VPN Service List");
	
	NSArray *services = [vpnInterfacer getListOfVPNServices];
	XLog(self, @"Service list found: %@", services);
	
	if (services == nil) {
		[self showRestartSidestepDialog];
	}
	else {
		[availableVPNServices addItemsWithTitles:services];
	}
	
	if ([services containsObject:[defaultsController selectedVPNService]]) {
		[availableVPNServices selectItemWithTitle:[defaultsController selectedVPNService]];
	}
	else {
		[defaultsController setSelectedVPNService:@"None"];
	}
	
}

- (void)updateUIForSelectedProxy {
	
	XLog(self, @"Updating UI for selected proxy");
	
	XLog(self, @"Selected proxy: %@", [defaultsController selectedProxy]);
	
	[proxyTabs selectTabViewItemWithIdentifier:[defaultsController selectedProxy]];
	
	if([[defaultsController selectedProxy] isEqualToString:@"1"]) {	// SSH selected
		[rerouteOrRestoreConnectionButton setHidden:FALSE];
		[connectVPNServiceButton setHidden:TRUE];
		[disconnectVPNServiceButton setHidden:TRUE];
		
		[statusMenuFirstSeparator setHidden:FALSE];
		[connectionStatus setHidden:FALSE];
		[proxyServerStatus setHidden:FALSE];
	}
	else {															// VPN selected
		[rerouteOrRestoreConnectionButton setHidden:TRUE];
		[connectVPNServiceButton setHidden:FALSE];
		[disconnectVPNServiceButton setHidden:FALSE];
		
		[statusMenuFirstSeparator setHidden:TRUE];
		[connectionStatus setHidden:TRUE];
		[proxyServerStatus setHidden:TRUE];
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

	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:helpWithProxyURL]];
	
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

- (void)selectProxyClicked :(id)sender {
	
	XLog(self, @"Selected proxy: %@", [defaultsController selectedProxy]);
	
	[self updateUIForSelectedProxy];
	
}

- (void)connectProxyClicked :(id)sender {
	
	XLog(self, @"Selected VPN service: %@", [defaultsController selectedVPNService]);
	
	[self openVPNConnectionAfterDelay:0];
	
}

- (void)disconnectProxyClicked :(id)sender {
	
	XLog(self, @"Selected VPN service: %@", [defaultsController selectedVPNService]);
	
	[self closeVPNConnection];
	
}

@end
