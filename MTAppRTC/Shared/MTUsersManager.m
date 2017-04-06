//
//  MTUsersManager.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTUsersManager.h"

@implementation MTUsersManager

#pragma mark - Singleton class method

static MTUsersManager *sharedManager;

+ (MTUsersManager *)sharedManager {
    if (!sharedManager) {
        sharedManager = [[MTUsersManager alloc] init];
        sharedManager.appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    }
    return sharedManager;
}

#pragma mark - Custom Methods

// Fetch the users registered in the app
- (void)fetchUsers {
    [[[self.appdelegate.refernce child:@"users"] queryOrderedByChild:@"email"] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        self.usersListArray = [[NSMutableArray alloc] init];
        
        //Filter the users except current users
        for (FIRDataSnapshot* child in snapshot.children) {
            if (![child.value[@"email"] isEqualToString:[FIRAuth auth].currentUser.email]) {
                [self.usersListArray addObject:child];
            }
        }
        
        //Manager will call the delegate methods so the view controller using delegate can handle the values
        if ([self.delegate respondsToSelector:@selector(usersList:error:)]) {
            [self.delegate usersList:self.usersListArray error:nil];
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(usersList:error:)]) {
            [self.delegate usersList:self.usersListArray error:error];
        }
    }];
}

- (void)fetchMissedCalls {
    [[[[self.appdelegate.refernce child:@"chat"] queryOrderedByChild:@"status"] queryEqualToValue:@"Missed"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        self.missedCallArray = [[NSMutableArray alloc] init];
        
        //Get the missed call users and thier count
        for (FIRDataSnapshot* child in snapshot.children) {
            if ([child.value[@"to"] isEqualToString:[FIRAuth auth].currentUser.email]) {
                NSString *email = child.value[@"from"];
                NSArray *filterObject = [self.missedCallArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"email == %@", email]];
                if (filterObject.count > 0) {
                    MTMissedCall *missedCall = (MTMissedCall *)filterObject.firstObject;
                    missedCall.count += 1;
                } else {
                    MTMissedCall *missedCall = [[MTMissedCall alloc] init];
                    missedCall.data = child.value;
                    missedCall.email = email;
                    missedCall.count = 1;
                    [self.missedCallArray addObject:missedCall];
                }
            }
        }
        
        //Manager will call the delegate methods so the view controller using delegate can handle the values
        if ([self.delegate respondsToSelector:@selector(missedCallList:error:)]) {
            [self.delegate missedCallList:self.missedCallArray error:nil];
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(missedCallList:error:)]) {
            [self.delegate missedCallList:self.missedCallArray error:error];
        }
    }];
}

//reset the manager values during logout
- (void)reset {
    self.usersListArray = nil;
    self.missedCallArray = nil;
}


@end
