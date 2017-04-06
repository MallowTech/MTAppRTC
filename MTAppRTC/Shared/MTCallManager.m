//
//  MTCallManager.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTCallManager.h"
#import "MTRTCHelper.h"

@implementation MTCallManager

#pragma mark - Singleton class method

static MTCallManager *sharedManager;

+ (MTCallManager *)sharedManager {
    if (!sharedManager) {
        sharedManager = [[MTCallManager alloc] init];
        sharedManager.appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    }
    return sharedManager;
}


#pragma mark - Custom Methods

// Random roomid generate based on timeinterval
- (NSString *)createRoom {
    NSString *randomString = [NSString stringWithFormat:@"M%f", [[NSDate date] timeIntervalSince1970]];
    randomString = [randomString stringByReplacingOccurrencesOfString:@"." withString:@"" ];
    return randomString;
}

//Here users is going to listen for observers when any incoming call comes
- (void)subscribedToCall {
    [[[[[self.appdelegate.refernce child:@"chat"] queryOrderedByChild:@"status"] queryEqualToValue:@"Requested"] queryLimitedToLast:1] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        //Check values and user is also not in another call
        if (snapshot.value != nil && ![snapshot.value isKindOfClass:[NSNull class]] && self.currentCall == nil) {
            NSLog(@"Request Received:%@", snapshot.value);
            NSMutableDictionary *dict = (NSMutableDictionary *)snapshot.value;
            NSString *to = [dict objectForKey:@"to"];
            NSString *from = [dict objectForKey:@"from"];
            
            //Check user is in sender side or receiver side
            if ([to isEqualToString:[FIRAuth auth].currentUser.email]) {
                self.currentCall = @{snapshot.key : dict};
                if ([self.delegate respondsToSelector:@selector(incomingCall:)]) {
                    [self.delegate incomingCall:self.currentCall];
                }
            } else if ([from isEqualToString:[FIRAuth auth].currentUser.email]) {
                self.currentCall = @{snapshot.key : dict};
                if ([self.delegate respondsToSelector:@selector(startCall:)]) {
                    [self.delegate startCall:self.currentCall];
                }
            }
            
            //Listen observer for current call status
            [self subscribeToCurrentCall:snapshot.key];
        }
    }];
    
}

// Start a call
- (void)startCall:(NSString *)to {
    NSDictionary *dictionary = @{@"from" : [FIRAuth auth].currentUser.email, @"to" : to, @"status" : @"Requested", @"roomId" : [self createRoom]};
    [[[self.appdelegate.refernce child:@"chat"] childByAutoId] setValue:dictionary withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (error != nil) {
            [MTRTCHelper showAlertWithTitle:@"Error!!" andMessage:@"Could not initiate a call. Please try again" inController:self.appdelegate.window.rootViewController];
        }
    }];
}

//User accept a call
- (void)acceptCall {
    if (self.currentCall != nil) {
        NSString *key = self.currentCall.allKeys.firstObject;
        NSDictionary *dictionary = [self.currentCall objectForKey:key];
        [dictionary setValue:@"Accepted" forKey:@"status"];
        [[[self.appdelegate.refernce child:@"chat"] child:key] setValue:dictionary withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            self.currentCall = nil;
        }];
    }
    
}

//User reject a call
- (void)rejectCall {
    if (self.currentCall != nil) {
        NSString *key = self.currentCall.allKeys.firstObject;
        NSDictionary *dictionary = [self.currentCall objectForKey:key];
        [dictionary setValue:@"Rejected" forKey:@"status"];
        [[[self.appdelegate.refernce child:@"chat"] child:key] setValue:dictionary withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            self.currentCall = nil;
        }];
    }
}

//Add a call status as missed call
- (void)missedACall {
    if (self.currentCall != nil) {
        NSString *key = self.currentCall.allKeys.firstObject;
        NSDictionary *dictionary = [self.currentCall objectForKey:key];
        [dictionary setValue:@"Missed" forKey:@"status"];
        [[[self.appdelegate.refernce child:@"chat"] child:key] setValue:dictionary withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            self.currentCall = nil;
        }];
    }
}

- (void)cancelACall:(NSDictionary *)call {
    NSString *key = call.allKeys.firstObject;
    NSDictionary *dictionary = [call objectForKey:key];
    [dictionary setValue:@"Cancelled" forKey:@"status"];
    [[[self.appdelegate.refernce child:@"chat"] child:key] setValue:dictionary withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        self.currentCall = nil;
    }];
}

//Listen for current status of the call
- (void)subscribeToCurrentCall:(NSString *)child {
    FIRDatabaseHandle handle = [[[self.appdelegate.refernce child:@"chat"] child:child] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if (snapshot.value != nil && ![snapshot.value isKindOfClass:[NSNull class]]) {
            NSLog(@"Request Received:%@", snapshot.value);
            NSMutableDictionary *dict = (NSMutableDictionary *)snapshot.value;
            NSString *from = [dict objectForKey:@"from"];
            NSString *status = [dict objectForKey:@"status"];
            if ([from isEqualToString:[FIRAuth auth].currentUser.email]) {
                if ([status isEqualToString:@"Accepted"]) {
                    if ([self.delegate respondsToSelector:@selector(callAccepted:)]) {
                        [self.delegate callAccepted:self.currentCall];
                    }
                    [self.appdelegate.refernce removeObserverWithHandle:handle];
                    self.currentCall = nil;
                } else if ([status isEqualToString:@"Rejected"]) {
                    if ([self.delegate respondsToSelector:@selector(callRejected:)]) {
                        [self.delegate callRejected:self.currentCall];
                    }
                    [self.appdelegate.refernce removeObserverWithHandle:handle];
                    self.currentCall = nil;
                }
            } else {
                if ([status isEqualToString:@"Cancelled"]) {
                    if ([self.delegate respondsToSelector:@selector(cancelCall)]) {
                        [self.delegate cancelCall];
                    }
                    [self.appdelegate.refernce removeObserverWithHandle:handle];
                    self.currentCall = nil;
                }
            }
        }
    }];
}

//reset the manager values during logout
- (void)reset {
    self.currentCall = nil;
}

@end
