//
//  MTRTCWebSocketChannel.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 30/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTRTCWebSocketChannel.h"

static NSString const *kMTRTCWSSMessageErrorKey = @"error";
static NSString const *kMTRTCWSSMessagePayloadKey = @"msg";

@implementation MTRTCWebSocketChannel

- (instancetype)initWithURL:(NSURL *)url restURL:(NSURL *)restURL delegate:(id<MTRTCWebSocketChannelDelegate>)delegate {
    if (self = [super init]) {
        self.url = url;
        self.restUrl = restURL;
        self.delegate = delegate;
        self.socket = [[SRWebSocket alloc] initWithURL:url];
        self.socket.delegate = self;
        [self.socket open];
    }
    return self;
}

- (void)dealloc {
    [self disconnect];
}

- (void)registerForRoomId:(NSString *)roomId clientId:(NSString *)clientId {
    self.roomId = roomId;
    self.clientId = clientId;
    if (self.state == kMTRTCWebSocketChannelStateOpen) {
        [self registerWithCollider];
    }
}

- (void)sendData:(NSData *)data {
    if (self.state == kMTRTCWebSocketChannelStateRegistered) {
        NSString *payload = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *dictionary = @{ @"cmd": @"send", @"msg": payload };
        NSData *messageJSONObject = [MTRTCHelper dataForDictionary:dictionary];
        NSString *messageString = [[NSString alloc] initWithData:messageJSONObject encoding:NSUTF8StringEncoding];
        [self.socket send:messageString];
    } else {
        NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", [self.restUrl absoluteString], self.roomId, self.clientId];
        NSURL *url = [NSURL URLWithString:urlString];
        [MTRTCHelper sendAsynchronousRequest:url withData:data completionHandler:nil];
    }
}

- (void)disconnect {
    if (self.state == kMTRTCWebSocketChannelStateClosed || self.state == kMTRTCWebSocketChannelStateError) {
        return;
    }
    [self.socket close];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", [self.restUrl absoluteString], self.roomId, self.clientId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"DELETE";
    request.HTTPBody = nil;
    [MTRTCHelper sendAsyncRequest:request completionHandler:nil];
}


#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    self.state = kMTRTCWebSocketChannelStateOpen;
    if (self.roomId.length && self.clientId.length) {
        [self registerWithCollider];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSString *messageString = message;
    NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Error parsing JSON: %@", jsonObject);
        return;
    }
    NSDictionary *wssMessage = jsonObject;
    NSString *errorString = wssMessage[kMTRTCWSSMessageErrorKey];
    if (errorString.length) {
        NSLog(@"Web Socket Error: %@", errorString);
        return;
    }
    NSString *payload = wssMessage[kMTRTCWSSMessagePayloadKey];
    MTRTCSignalingMessage *signalingMessage = [MTRTCSignalingMessage messageFromJSONString:payload];
    [self.delegate channel:self didReceiveMessage:signalingMessage];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    self.state = kMTRTCWebSocketChannelStateError;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    self.state = kMTRTCWebSocketChannelStateClosed;
    [self.delegate channel:self didChangeState:self.state];
}

#pragma mark - Register Method

- (void)registerWithCollider {
    if (self.state == kMTRTCWebSocketChannelStateRegistered) {
        return;
    }
    NSDictionary *dictionary = @{ @"cmd": @"register", @"roomid" : self.roomId, @"clientid" : self.clientId };
    NSData *message = [MTRTCHelper dataForDictionary:dictionary];
    NSString *messageString = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    [self.socket send:messageString];
    self.state = kMTRTCWebSocketChannelStateRegistered;
}

@end
