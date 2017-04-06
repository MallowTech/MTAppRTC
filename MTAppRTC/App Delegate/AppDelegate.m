//
//  AppDelegate.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 27/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCSSLAdapter.h>
#import <WebRTC/RTCLogging.h>
#import "MTCallManager.h"
#import "MTIncomingCallViewController.h"
#import "MTUsersManager.h"
#import "MTRTCCallViewController.h"

@interface AppDelegate () <MTCallManagerDelegate, MTIncomingCallViewDelegate>

@property (strong, nonatomic) MTCallManager *callManager;
@property (strong, nonatomic) MTIncomingCallViewController *incomingCallViewController;
@property (strong, nonatomic) UINavigationController *callNavigationViewController;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //Initialize SSL
    RTCInitializeSSL();
    
    //WebRTC Debug Logging
    RTCLogEx(RTCLoggingSeverityError, @"Error");
    
    //Ask permission for Audio and Video
    [self permissionForAudioAndVideo];
    
    //Initialize Firebase
    [FIRApp configure];
    self.refernce = [[FIRDatabase database] reference];
    
    //Check whether user is loggedIn or not
    BOOL isLoggedIn = [[NSUserDefaults standardUserDefaults] objectForKey:@"Login"];
    self.callManager = [MTCallManager sharedManager];
    self.callManager.delegate = self;
    if (isLoggedIn) {// If login show the users list
        [self showUsersListView];
    } else {//show the login view
        [self showLoginView];
    }

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    
    RTCCleanupSSL();
}

#pragma mark - Custom Methods

// Show Users list
- (void)showUsersListView {
    //Observer for incoming call
    [self.callManager subscribedToCall];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *controller = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"UsersNavigationVC"];
    self.window.rootViewController = controller;
}

// Show Login View
- (void)showLoginView {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *controller = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"LoginNavigationVC"];
    self.window.rootViewController = controller;
}

// User Logout
- (void)logout {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Login"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[FIRAuth auth] signOut:nil];
    [self.refernce removeAllObservers];
    [[MTUsersManager sharedManager] reset];
    [[MTCallManager sharedManager] reset];
    [self.timer invalidate];
    [self showLoginView];
}

// Show a view for incoming call Accept/Reject
- (void)showIncomingCallView:(NSDictionary *)details {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MTIncomingCallViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"MTIncomingCallViewController"];
    controller.callDetails = details;
    controller.delegate = self;
    self.incomingCallViewController = controller;
    [self.window.rootViewController presentViewController:self.incomingCallViewController animated:YES completion:nil];
}

// Show a video chat view
- (void)showCallerView:(NSDictionary *)details {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"CallerNavigationVC"];
    MTRTCCallViewController *controller = (MTRTCCallViewController *)navigationController.topViewController;
    controller.callDetails = details;
    self.callNavigationViewController = navigationController;
    [self.window.rootViewController presentViewController:self.callNavigationViewController animated:YES completion:nil];
}

// Dismiss the chat view
- (void)dismissChatView:(NSDictionary *)dictionary {
    [self.callNavigationViewController dismissViewControllerAnimated:YES completion:nil];
    [self.callManager missedACall];
}

// Dismiss the Incoming call view
- (void)dismissIncomingCallView {
    [self.incomingCallViewController dismissViewControllerAnimated:NO completion:nil];
    self.incomingCallViewController.delegate = nil;
    self.incomingCallViewController = nil;
}


#pragma mark - CallManager Delegate Methods

- (void)callAccepted:(NSDictionary *)call {
    [self.timer invalidate];
}

- (void)callRejected:(NSDictionary *)call {
    [self.timer invalidate];
}

- (void)startCall:(NSDictionary *)call {
    [self showCallerView:call];
    
    // Schedule a timer for 30 seconds for showing caller screen
    self.timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(dismissChatView:) userInfo:call repeats:false];
}

- (void)incomingCall:(NSDictionary *)call {
    [self showIncomingCallView:call];
    
    // Schedule a timer for 30 seconds for showing incoming call screen
    self.timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(dismissIncomingCallView) userInfo:call repeats:false];
}

#pragma mark - CallManager Delegate Methods

- (void)acceptedCall:(NSDictionary *)call {
    //User accepted the call
    [self.callManager acceptCall];
    //Dismiss the incoming call view
    [self dismissIncomingCallView];
    //Show video chat view
    [self showCallerView:call];
}

- (void)rejectedCall:(NSDictionary *)call {
    //User rejected the call
    [self.callManager rejectCall];
    //Dismiss the incoming call view
    [self dismissIncomingCallView];
}

-(void)permissionForAudioAndVideo {
    // Video permission
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        
        // Audio permission
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            
        }];
        
    }];
}

@end
