#ifndef kCFCoreFoundationVersionNumber_iOS_4_0
#define kCFCoreFoundationVersionNumber_iOS_4_0 550.32
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_5_0
#define kCFCoreFoundationVersionNumber_iOS_5_0 675.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_6_0
#define kCFCoreFoundationVersionNumber_iOS_6_0 793.00
#endif

@interface SBAlertItem : NSObject
@property(readonly, retain) id alertSheet;
- (void)dismiss;
@end

@interface SBAlertItemsController : NSObject
+ (id)sharedInstance;
- (void)activateAlertItem:(id)item;
@end

@interface StartupAlertItem : SBAlertItem @end

//==============================================================================

%hook StartupAlertItem

- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)require {
    NSString *title = @"Alert At Startup";
    NSString *body = @"Until you tap OK, this alert will remain, even after relocking.";

    // NOTE: alertView is a UIAlertView in iOS 4.0 and greater, but a
    //       UIModalView in earlier firmware versions.
    id alertView = [self alertSheet];
    [alertView setDelegate:self];
    [alertView setTitle:title];
    [alertView setMessage:body];
    [alertView addButtonWithTitle:@"OK"];
}

- (BOOL)shouldShowInLockScreen { return NO; }

%end

//------------------------------------------------------------------------------

%hook StartupAlertItem %group GFirmware_LT_40

%new
- (void)alertSheet:(id)sheet buttonClicked:(int)clicked {
    [self dismiss];
}

%end %end

//------------------------------------------------------------------------------

%hook StartupAlertItem %group GFirmware_GTE_40_LT_50

- (void)didDeactivateForReason:(int)reason {
    %orig;

    if (reason == 0) {
        // Was deactivated due to lock, not user interaction
        // FIXME: Is there no better way to get the alert to reappear?
        [[objc_getClass("SBAlertItemsController") sharedInstance] activateAlertItem:self];
    }
}

%end %end

//------------------------------------------------------------------------------

%hook StartupAlertItem %group GFirmware_GTE_50_LT_60

- (BOOL)reappearsAfterLock { return YES; }

%end %end

//------------------------------------------------------------------------------

%hook StartupAlertItem %group GFirmware_GTE_60

// FIXME: Is this the correct way to do this?
//        And even though reappearsAfterLock returns NO by default,
//        the alert still reappears... why?
- (BOOL)behavesSuperModally { return YES; }

%end %end

//==============================================================================

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    StartupAlertItem *alertItem = [[objc_getClass("StartupAlertItem") alloc] init];
    [[objc_getClass("SBAlertItemsController") sharedInstance] activateAlertItem:alertItem];
    [alertItem release];
}

%end

//==============================================================================

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Register new subclass
    Class $SuperClass = objc_getClass("SBAlertItem");
    if ($SuperClass != Nil) {
        Class $StartupAlertItem = objc_allocateClassPair($SuperClass, "StartupAlertItem", 0);
        if ($StartupAlertItem != Nil) {
            objc_registerClassPair($StartupAlertItem);
            %init;

            // NOTE: Confirmed working with iOS 3.0, 4.0, 5.1.1 and 6.0.
            // FIXME: Add support for iOS 2.x.
            if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_4_0) {
                %init(GFirmware_LT_40);
            } else if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_5_0) {
                %init(GFirmware_GTE_40_LT_50);
            } else if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) {
                %init(GFirmware_GTE_50_LT_60);
            } else {
                %init(GFirmware_GTE_60);
            }
        }
    }

    [pool release];
}

/* vim: set filetype=objcpp sw=4 ts=4 expandtab tw=80 ff=unix: */
