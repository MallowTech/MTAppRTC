//
//  MTCallManager.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@protocol MTCallManagerDelegate <NSObject>
- (void)callAccepted:(NSDictionary *)call;
- (void)callRejected:(NSDictionary *)call;
- (void)incomingCall:(NSDictionary *)call;
- (void)startCall:(NSDictionary *)call;

@end

@interface MTCallManager : NSObject

+ (MTCallManager *)sharedManager;

@property (nonatomic, weak) id<MTCallManagerDelegate> delegate;
@property (strong, nonatomic) AppDelegate *appdelegate;
@property (strong, nonatomic) NSDictionary *currentCall;

- (void)subscribedToCall;
- (void)startCall:(NSString *)to;
- (void)acceptCall;
- (void)rejectCall;
- (void)missedACall;
- (void)reset;

@end
