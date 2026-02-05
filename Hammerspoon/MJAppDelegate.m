#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import "MJAppDelegate.h"
#import "MJConsoleWindowController.h"
#import "MJPreferencesWindowController.h"
#import "MJDockIcon.h"
#import "MJMenuIcon.h"
#import "MJLua.h"
#import "MJVersionUtils.h"
#import "MJConfigUtils.h"
#import "MJFileUtils.h"
#import "MJAccessibilityUtils.h"
#import "HSLogger.h"
#import "variables.h"
#import "secrets.h"

#ifdef SENTRY_API_URL
@import Sentry;
#endif

@implementation MJAppDelegate

#pragma mark - LateNite App Validation

+ (BOOL)isValidLateNiteAppInstalled {
    NSLog(@"[LateNite Validation] Starting validation check...");

    NSArray *lateNiteBundleIDs = @[
        @"com.latenitefilms.ATEMExporter",
        @"com.latenitefilms.BRAWToolbox",
        @"com.latenitefilms.Capacitor",
        @"com.latenitefilms.FastCollections",
        @"com.latenitefilms.GyroflowToolbox",
        @"com.latenitefilms.LUTRobot",
        @"com.latenitefilms.MarkerToolbox",
        @"com.latenitefilms.Metaburner",
        @"com.latenitefilms.NewsImport",
        @"com.latenitefilms.RecallToolbox",
        @"com.latenitefilms.TransferToolbox"
    ];

    NSString *expectedTeamID = @"A5HDJTY9X5";
    NSString *expectedAuthority = @"Apple Mac OS Application Signing";
    NSLog(@"[LateNite Validation] Expected Team ID: %@", expectedTeamID);
    NSLog(@"[LateNite Validation] Expected Authority: %@", expectedAuthority);

    for (NSString *bundleID in lateNiteBundleIDs) {
        NSLog(@"[LateNite Validation] Checking bundle ID: %@", bundleID);

        NSArray *appURLs = (__bridge_transfer NSArray *)LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef)bundleID, NULL);

        if (appURLs && appURLs.count > 0) {
            NSLog(@"[LateNite Validation]   Found %lu app(s) for bundle ID", (unsigned long)appURLs.count);

            for (NSURL *appURL in appURLs) {
                NSLog(@"[LateNite Validation]   Checking app at path: %@", appURL.path);

                // Check code signature
                SecStaticCodeRef staticCode = NULL;
                OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)appURL, kSecCSDefaultFlags, &staticCode);

                if (status != errSecSuccess) {
                    NSLog(@"[LateNite Validation]   ERROR: SecStaticCodeCreateWithPath failed with status: %d", (int)status);
                    continue;
                }

                if (staticCode == NULL) {
                    NSLog(@"[LateNite Validation]   ERROR: staticCode is NULL");
                    continue;
                }

                NSLog(@"[LateNite Validation]   Successfully created static code reference");

                CFDictionaryRef signingInfo = NULL;
                status = SecCodeCopySigningInformation(staticCode, kSecCSSigningInformation, &signingInfo);

                if (status != errSecSuccess) {
                    NSLog(@"[LateNite Validation]   ERROR: SecCodeCopySigningInformation failed with status: %d", (int)status);
                    CFRelease(staticCode);
                    continue;
                }

                if (signingInfo == NULL) {
                    NSLog(@"[LateNite Validation]   ERROR: signingInfo is NULL");
                    CFRelease(staticCode);
                    continue;
                }

                NSLog(@"[LateNite Validation]   Successfully retrieved signing information");

                NSDictionary *signingDict = (__bridge NSDictionary *)signingInfo;

                // Check Team ID
                NSString *teamID = signingDict[(__bridge NSString *)kSecCodeInfoTeamIdentifier];
                NSLog(@"[LateNite Validation]   Team ID: %@", teamID ?: @"(nil)");

                BOOL teamIDMatches = [teamID isEqualToString:expectedTeamID];
                NSLog(@"[LateNite Validation]   Team ID match: %@", teamIDMatches ? @"YES" : @"NO");

                if (!teamIDMatches) {
                    CFRelease(signingInfo);
                    CFRelease(staticCode);
                    continue;
                }

                // Check for Mac App Store signature (Apple Mac OS Application Signing)
                NSArray *certificateChain = signingDict[(__bridge NSString *)kSecCodeInfoCertificates];
                BOOL isAppStoreApp = NO;

                if (certificateChain && certificateChain.count > 0) {
                    SecCertificateRef certificate = (__bridge SecCertificateRef)certificateChain[0];
                    CFStringRef commonName = NULL;
                    OSStatus certStatus = SecCertificateCopyCommonName(certificate, &commonName);

                    if (certStatus == errSecSuccess && commonName != NULL) {
                        NSString *commonNameStr = (__bridge NSString *)commonName;
                        NSLog(@"[LateNite Validation]   Certificate Authority: %@", commonNameStr);
                        isAppStoreApp = [commonNameStr isEqualToString:expectedAuthority];
                        NSLog(@"[LateNite Validation]   Is App Store app: %@", isAppStoreApp ? @"YES" : @"NO");
                        CFRelease(commonName);
                    }
                }

                if (teamIDMatches && isAppStoreApp) {
                    NSLog(@"[LateNite Validation] SUCCESS: Found valid Mac App Store LateNite app at %@", appURL.path);
                    CFRelease(signingInfo);
                    CFRelease(staticCode);
                    return YES;
                }

                CFRelease(signingInfo);
                CFRelease(staticCode);
            }
        } else {
            NSLog(@"[LateNite Validation]   No apps found for this bundle ID");
        }
    }

    NSLog(@"[LateNite Validation] FAILED: No valid Mac App Store LateNite app found");
    return NO;
}

+ (void)showNoValidAppAlert {
    [NSApp activateIgnoringOtherApps:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = @"CommandPost v2 (and later) requires a paid LateNite App installed.";
    alert.informativeText = @"After 9 years of free updates, to ensure that CommandPost continues to be developed, improved, and stay open-source, we've decided that you need at least ONE paid LateNite application installed to use CommandPost moving forward.\n\nThank you to EVERYONE who has supported CommandPost throughout these years!\n\nPlease download and install a LateNite App from the Mac App Store or roll back to a previous version of CommandPost v1.";

    [alert addButtonWithTitle:@"Open Mac App Store"];
    [alert addButtonWithTitle:@"Quit"];

    NSModalResponse response = [alert runModal];

    if (response == NSAlertFirstButtonReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://apps.apple.com/au/developer/latenite-films-pty-ltd/id1652018641"]];
    }

    [NSApp terminate:nil];
}

#pragma mark - Application Delegate Methods

- (BOOL) applicationShouldHandleReopen:(NSApplication*)theApplication hasVisibleWindows:(BOOL)hasVisibleWindows {
    callDockIconCallback();
    if (HSOpenConsoleOnDockClickEnabled()) {
        [[MJConsoleWindowController singleton] showWindow: nil];
    };
    return NO;
}

-(void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    // Set up an early event manager handler so we can catch URLs used to launch us
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
    self.startupEvent = nil;
    self.startupFile = nil;
    self.openFileDelegate = nil;
    self.updateAvailable = nil;
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    self.startupEvent = event;
}

#ifndef NO_INTENTS
- (id)application:(NSApplication *)application handlerForIntent:(INIntent *)intent  API_AVAILABLE(macos(11.0)){
    NSLog(@"handlerForIntent: Checking for HSExecuteLuaIntent");
    if ([intent isKindOfClass:[HSExecuteLuaIntent class]]) {
        NSLog(@"handlerForIntent: Found HSExecuteLuaIntent, dispatching to HSExecuteLuaIntentHandler");
        return ([[HSExecuteLuaIntentHandler alloc] init]);
    }
    return nil;
}
#endif

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)fileAndPath {
    NSString *typeOfFile = [[NSWorkspace sharedWorkspace] typeOfFile:fileAndPath error:nil];

    if ([typeOfFile isEqualToString:@"org.latenitefilms.commandpost.plugin"]) {
        // This is a Plugin, so we will attempt to copy it to the Plugin directory
        NSError *fileError;
        BOOL success = NO;
        BOOL upgrade = NO;
        NSString *spoonPath = [@"~/Library/Application Support/CommandPost/Plugins/" stringByExpandingTildeInPath];
        NSString *spoonName = [fileAndPath lastPathComponent];
        NSString *dstSpoonFullPath = [spoonPath stringByAppendingPathComponent:spoonName];

        if ([dstSpoonFullPath isEqualToString:fileAndPath]) {
            NSLog(@"User double clicked on a Spoon in %@, skipping", MJConfigDirAbsolute());
            return YES;
        }

        NSFileManager *fileManager = [NSFileManager defaultManager];

        // Remove any preexisting copy of the Spoon
        if ([fileManager fileExistsAtPath:dstSpoonFullPath]) {
            NSLog(@"Plugin already exists at %@, removing the old version", dstSpoonFullPath);
            upgrade = YES;
            success = [fileManager removeItemAtPath:dstSpoonFullPath error:&fileError];
            if (!success) {
                NSLog(@"Unable to remove existing Plugin (%@):%@", dstSpoonFullPath, fileError);
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"OK"];
                [alert setMessageText:@"Error upgrading Plugin"];
                [alert setInformativeText:[NSString stringWithFormat:@"%@\n\nSource: %@\nDest: %@", fileError.localizedDescription, fileAndPath, spoonPath]];
                [alert setAlertStyle:NSAlertStyleCritical];
                [alert runModal];
                return YES;
            }
        }


        success = [[NSFileManager defaultManager] moveItemAtPath:fileAndPath toPath:dstSpoonFullPath error:&fileError];
        if (!success) {
            NSLog(@"Unable to move %@ to %@: %@", fileAndPath, spoonPath, fileError);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"Error installing Plugin"];
            [alert setInformativeText:[NSString stringWithFormat:@"%@\n\nSource: %@\nDest: %@", fileError.localizedDescription, fileAndPath, spoonPath]];
            [alert setAlertStyle:NSAlertStyleCritical];
            [alert runModal];
        } else {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = [NSString stringWithFormat:@"Plugin %@", upgrade ? @"upgraded" : @"installed"];
            notification.informativeText = [NSString stringWithFormat:@"%@ is now available%@", spoonName, upgrade ? @", " : @""];
            notification.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            MJLuaReplace(); // Reload CommandPost
        }
        return YES; // Note that we always return YES here because otherwise macOS tells the user that we can't open Spoons, which is ludicrous
    }

    NSString *fileExtension = [fileAndPath pathExtension];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSArray *supportedExtensions = [infoDict valueForKeyPath:@"CFBundleDocumentTypes.CFBundleTypeExtensions"];
    NSArray *flatSupportedExtensions = [supportedExtensions valueForKeyPath:@"@unionOfArrays.self"];

    // Files to be processed by hs.urlevent
    if ([flatSupportedExtensions containsObject:fileExtension]) {
        if (!self.openFileDelegate) {
            self.startupFile = fileAndPath;
        } else {
            if ([self.openFileDelegate respondsToSelector:@selector(callbackWithURL:senderPID:)]) {
                [self.openFileDelegate callbackWithURL:fileAndPath senderPID:-1];
            }
        }
    } else {
        // Trigger File Dropped to Dock Icon Callback
        fileDroppedToDockIcon(fileAndPath);
    }

    return YES;
}

- (BOOL)application:(NSApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(nonnull void (^)(NSArray<id<NSUserActivityRestoring>> *_Nullable))restorationHandler
{
  //NSLog(@"Open URL in NSUserActivityTypeBrowsingWeb");
  if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
    [[NSWorkspace sharedWorkspace] openURL:userActivity.webpageURL];
    return YES;
  }
  return NO;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Check for valid LateNite app before proceeding
    if (![MJAppDelegate isValidLateNiteAppInstalled]) {
        [MJAppDelegate showNoValidAppAlert];
        return; // This won't be reached as showNoValidAppAlert terminates the app
    }

    BOOL isTesting = NO;

    // User is holding down Command (0x37) & Option (0x3A) keys:
    if (CGEventSourceKeyState(kCGEventSourceStateCombinedSessionState,0x3A) && CGEventSourceKeyState(kCGEventSourceStateCombinedSessionState,0x37)) {

        NSAlert *alert = [[NSAlert alloc] init];
        NSButton *deleteButton = [alert addButtonWithTitle:@"Delete Preferences"];
        deleteButton.hasDestructiveAction = YES;

        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Do you want to delete the preferences?"];
        [alert setInformativeText:@"Deleting the preferences will reset all application settings to their defaults."];
        [alert setAlertStyle:NSAlertStyleWarning];

        if ([alert runModal] == NSAlertFirstButtonReturn) {

            // Reset Preferences:
            NSDictionary * allObjects;
            allObjects = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
            for(NSString *key in allObjects)
            {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey: key];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];

        }
    }

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityChanged:) name:@"com.apple.accessibility.api" object:nil];

    // Remove our early event manager handler so hs.urlevent can register for it later, if the user has it configured to
    [[NSAppleEventManager sharedAppleEventManager] removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL];

    if(NSClassFromString(@"XCTest") != nil) {
        // Hammerspoon Tests
        NSLog(@"in testing mode!");
        isTesting = YES;

        NSBundle *mainBundle = [NSBundle mainBundle];
        NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/Contents/Plugins/Hammerspoon Tests.xctest", mainBundle.bundlePath]];
        NSString *lsUnitPath = [bundle pathForResource:@"lsunit" ofType:@"lua"];
        const char *fsPath = [lsUnitPath fileSystemRepresentation];

        if (!fsPath) {
            NSLog(@"Unable to find lsunit.lua in Hammerspoon Tests.xctest. We're about to crash, sorry!");
            abort();
        } else {
            NSLog(@"testing lsunit.lua");
        }
        MJConfigFile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:fsPath length:strlen(fsPath)];
    } else if ([[[NSProcessInfo processInfo] environment] objectForKey:@"XCTESTING"]) {
        // Hammerspoon UI Tests
        NSLog(@"in UI testing mode");
        NSString *initPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingString:@"/Hammerspoon UI Tests-Runner.app/Contents/PlugIns/Hammerspoon UI Tests.xctest/Contents/Resources/init.lua"];
        const char *fsPath = [initPath fileSystemRepresentation];

        if (!fsPath) {
            NSLog(@"Unable to find init.lua in Hammerspoon UI Tests. We're about to crash, sorry!");
            abort();
        } else {
            NSLog(@"UI testing init.lua");
        }
        MJConfigFile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:fsPath length:strlen(fsPath)];
        [self showConsoleWindow:nil];
    } else {
        // No test environment detected, this is a live user run
        NSString* userMJConfigFile = [[NSUserDefaults standardUserDefaults] stringForKey:@"MJConfigFile"];
        if (userMJConfigFile) MJConfigFile = userMJConfigFile ;

        // Ensure we have a Plugin directory
        NSString *spoonsPath = [@"~/Library/Application Support/CommandPost/Plugins/" stringByExpandingTildeInPath]; //[MJConfigDir() stringByAppendingPathComponent:@"Spoons"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL spoonsPathIsDir;
        BOOL spoonsPathExists = [fileManager fileExistsAtPath:spoonsPath isDirectory:&spoonsPathIsDir];

        NSLog(@"Determined Plugins path will be: %@ (exists: %@, isDir: %@)", spoonsPath, spoonsPathExists ? @"YES" : @"NO", spoonsPathIsDir ? @"YES" : @"NO");

        if (spoonsPathExists && !spoonsPathIsDir) {
            NSLog(@"ERROR: %@ exists, but is a file", spoonsPath);
            abort();
        }

        if (!spoonsPathExists) {
            NSLog(@"Creating Plugins directory at: %@", spoonsPath);
            [[NSFileManager defaultManager] createDirectoryAtPath:spoonsPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }

    // Become the handler for events from macOS Services
    [NSApp setServicesProvider:self];

    MJEnsureDirectoryExists(MJConfigDir());
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:MJConfigDir()];

    [self registerDefaultDefaults];

    // Enable Sentry, if we have an API URL available
#ifdef SENTRY_API_URL
    if (HSUploadCrashData() && !isTesting) {
        SentryEvent* (^sentryWillUploadCrashReport) (SentryEvent *event) = ^SentryEvent* (SentryEvent *event) {
            if ([event.extra objectForKey:@"MjolnirModuleLoaded"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                   [self showMjolnirMigrationNotification];
                });
            }
            return event;
        };

        [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
            options.dsn = @SENTRY_API_URL;
            options.beforeSend = sentryWillUploadCrashReport;
            options.releaseName = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
            options.enableAppHangTracking = NO;
            options.debug = YES; // Enabled debug when first installing is always helpful
        }];
    }
#endif

    // Become the Sparkle delegate, if it's available
    if (NSClassFromString(@"SUUpdater")) {
        NSString *frameworkPath = [[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:@"Sparkle.framework"];
        if ([[NSBundle bundleWithPath:frameworkPath] load]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            id sharedUpdater = [NSClassFromString(@"SUUpdater")  performSelector:@selector(sharedUpdater)];
            NSMethodSignature * mySignature = [NSClassFromString(@"SUUpdater") instanceMethodSignatureForSelector:@selector(setDelegate:)];
            NSInvocation * myInvocation = [NSInvocation invocationWithMethodSignature:mySignature];
            [myInvocation setTarget:sharedUpdater];
            // even though signature specifies this, we need to specify it in the invocation, since the signature is re-usable
            // for any method which accepts the same signature list for the target.
            [myInvocation setSelector:@selector(setDelegate:)];
            [myInvocation setArgument:(void *)&self atIndex:2];
            [myInvocation invoke];
#pragma clang diagnostic pop
        }
    }

    MJMenuIconSetup(self.menuBarMenu);
    MJDockIconSetup();
    [[MJConsoleWindowController singleton] setup];
    MJLuaCreate();
    self.luaInitialized = YES;

    //if (!MJAccessibilityIsEnabled())
        //[[MJPreferencesWindowController singleton] showWindow: nil];
}


// Dragging & Dropping of Text to Dock Item
-(void) processDockIconDraggedText:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    NSString *pboardString = [pboard stringForType:NSPasteboardTypeString];
    textDroppedToDockIcon(pboardString);
}

// Dragging & Dropping of File to Dock Item
-(void) processDockIconDraggedFile:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    NSArray *filePaths = [pboard propertyListForType:NSFilenamesPboardType];
    for (NSString *filePath in filePaths) {
        fileDroppedToDockIcon(filePath);
    }
}

- (void) accessibilityChanged:(NSNotification*)note {
    HSNSLOG(@"accessibilityChanged: %@", MJAccessibilityIsEnabled() ? @"ENABLED" : @"DISABLED");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        callAccessibilityStateCallback();
    });
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if (self.luaInitialized) {
        MJLuaDestroy();
    }
    return NSTerminateNow;
}

- (void) registerDefaultDefaults {
    [[NSUserDefaults standardUserDefaults]
     registerDefaults: @{@"NSApplicationCrashOnExceptions": @YES,
                         MJShowDockIconKey: @NO,
                         MJShowMenuIconKey: @NO,
                         HSAutoLoadExtensions: @YES,
                         HSUploadCrashDataKey: @YES,
                         HSAppleScriptEnabledKey: @NO,
                         HSOpenConsoleOnDockClickKey: @YES,
                         HSPreferencesDarkModeKey: @YES,
                         HSConsoleDarkModeKey: @YES,
                         }];
}

- (IBAction) reloadConfig:(id)sender {
    MJLuaReplace();
}

- (IBAction) showConsoleWindow:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[MJConsoleWindowController singleton] showWindow: nil];
}

- (IBAction) showPreferencesWindow:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[MJPreferencesWindowController singleton] showWindow: nil];
}

- (IBAction) showAboutPanel:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    @try {
        [[NSApplication sharedApplication] orderFrontStandardAboutPanel: nil];
    } @catch (NSException *exception) {
        [[LuaSkin sharedWithState:NULL] logError:@"Unable to open About dialog. This may mean your CommandPost installation is corrupt. Please re-install it!"];
    }
}

- (IBAction) quitHammerspoon:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction) openConfig:(id)sender {
    NSString* path = MJConfigFileFullPath();

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path
                                                contents:[NSData data]
                                              attributes:nil];
    }

    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    if ([workspace openFile:path] == NO) {
        // No app is associated with .lua files, so fall back on TextEdit
        [workspace openFile:path withApplication:@"TextEdit" andDeactivate:YES];
    }
}

- (void)showMjolnirMigrationNotification {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"CommandPost crash detected"];
    [alert setInformativeText:@"Your init.lua is loading Mjolnir modules and a previous launch crashed.\n\nCommandPost ships with updated versions of many of the Mjolnir modules, with both new features and many bug fixes.\n\nPlease consult our API documentation and migrate your config."];
    [alert setAlertStyle:NSAlertStyleCritical];
    [alert runModal];
}

#pragma mark - Sparkle delegate methods
- (void)updater:(id)updater didFindValidUpdate:(id)update {
    NSLog(@"Update found: %@ (Build: %@)", [update valueForKey:@"displayVersionString"], [update valueForKey:@"versionString"]);
    self.updateAvailable = [update valueForKey:@"versionString"];
    self.updateAvailableDisplayVersion = [update valueForKey:@"displayVersionString"];
}

- (void)updaterDidNotFindUpdate:(id)update {
    self.updateAvailable = nil;
    self.updateAvailableDisplayVersion = nil;
}

@end

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}
