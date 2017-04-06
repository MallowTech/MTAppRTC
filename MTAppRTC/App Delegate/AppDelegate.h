//
//  AppDelegate.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 27/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Firebase;
@class  MTCallManager;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) FIRDatabaseReference *refernce;

- (void)showUsersListView;
- (void)showLoginView;
- (void)logout;

@end

