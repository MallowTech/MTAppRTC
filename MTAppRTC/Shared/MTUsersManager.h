//
//  MTUsersManager.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "MTMissedCall.h"

@protocol MTUsersManagerDelegate <NSObject>
- (void)usersList:(NSMutableArray *)users error:(NSError *)error;
- (void)missedCallList:(NSMutableArray *)missedCalls error:(NSError *)error;
@end

@interface MTUsersManager : NSObject

+ (MTUsersManager *)sharedManager;

@property (nonatomic, weak) id<MTUsersManagerDelegate> delegate;
@property (strong, nonatomic) AppDelegate *appdelegate;
@property (strong, nonatomic) NSMutableArray *usersListArray;
@property (strong, nonatomic) NSMutableArray<MTMissedCall *> *missedCallArray;

- (void)fetchUsers;
- (void)fetchMissedCalls;
- (void)reset;

@end
