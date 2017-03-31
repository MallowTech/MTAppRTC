//
//  MTRTCWebSocketChannel.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 30/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SRWebSocket.h"
#import "MTRTCHelper.h"
#import "MTRTCSignalingMessage.h"

typedef NS_ENUM(NSInteger, MTRTCWebSocketChannelState) {
    kMTRTCWebSocketChannelStateClosed,
    kMTRTCWebSocketChannelStateOpen,
    kMTRTCWebSocketChannelStateRegistered,
    kMTRTCWebSocketChannelStateError
};

@class MTRTCWebSocketChannel;
@class MTRTCSignalingMessage;
@protocol MTRTCWebSocketChannelDelegate <NSObject>

- (void)channel:(MTRTCWebSocketChannel *)channel didChangeState:(MTRTCWebSocketChannelState)state;
- (void)channel:(MTRTCWebSocketChannel *)channel didReceiveMessage:(MTRTCSignalingMessage *)message;

@end

@interface MTRTCWebSocketChannel : NSObject <SRWebSocketDelegate>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *restUrl;
@property (nonatomic, strong) SRWebSocket *socket;

@property (nonatomic, strong) NSString *roomId;
@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, assign) MTRTCWebSocketChannelState state;
@property (nonatomic, weak) id<MTRTCWebSocketChannelDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url restURL:(NSURL *)restURL delegate:(id<MTRTCWebSocketChannelDelegate>)delegate;
- (void)registerForRoomId:(NSString *)roomId clientId:(NSString *)clientId;
- (void)sendData:(NSData *)data;

@end
