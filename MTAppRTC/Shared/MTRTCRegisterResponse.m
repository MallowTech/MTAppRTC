//
//  MTRTCRegisterResponse.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 28/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTRTCRegisterResponse.h"
#import "MTRTCHelper.h"
#import "MTRTCSignalingMessage.h"

static NSString const *kMTRTCRegisterResultKey = @"result";
static NSString const *kMTRTCRegisterResultParamsKey = @"params";
static NSString const *kMTRTCRegisterInitiatorKey = @"is_initiator";
static NSString const *kMTRTCRegisterRoomIdKey = @"room_id";
static NSString const *kMTRTCRegisterClientIdKey = @"client_id";
static NSString const *kMTRTCRegisterMessagesKey = @"messages";
static NSString const *kMTRTCRegisterWebSocketURLKey = @"wss_url";
static NSString const *kMTRTCRegisterWebSocketRestURLKey = @"wss_post_url";

@implementation MTRTCRegisterResponse

+ (MTRTCRegisterResponse *)responseFromJSONData:(NSData *)data {
    NSDictionary *responseDictionary = [MTRTCHelper dictionaryFromData:data];
    if (([responseDictionary isKindOfClass:[NSNull class]]) && (responseDictionary == nil)) {
        return nil;
    }
    MTRTCRegisterResponse *response = [[MTRTCRegisterResponse alloc] init];
    NSString *resultString = responseDictionary[kMTRTCRegisterResultKey];
    response.registerResultType = [self resultTypeFromString:resultString];
    NSDictionary *params = responseDictionary[kMTRTCRegisterResultParamsKey];
    
    response.isInitiator = [params[kMTRTCRegisterInitiatorKey] boolValue];
    response.roomId = params[kMTRTCRegisterRoomIdKey];
    response.clientId = params[kMTRTCRegisterClientIdKey];
    
    // Parse messages.
    NSArray *messages = params[kMTRTCRegisterMessagesKey];
    NSMutableArray *signalingMessages = [NSMutableArray arrayWithCapacity:messages.count];
    for (NSString *message in messages) {
        MTRTCSignalingMessage *signalingMessage =
        [MTRTCSignalingMessage messageFromJSONString:message];
        [signalingMessages addObject:signalingMessage];
    }
    response.messages = signalingMessages;
    
    // Parse websocket urls.
    response.webSocketURLString = params[kMTRTCRegisterWebSocketURLKey];
    response.webSocketRestURLString = params[kMTRTCRegisterWebSocketRestURLKey];
    
    return response;
}

+ (MTRTCRegisterResultType)resultTypeFromString:(NSString *)resultString {
    MTRTCRegisterResultType result = kMTRTCRegisterResultTypeUnknown;
    if ([resultString isEqualToString:@"SUCCESS"]) {
        result = kMTRTCRegisterResultTypeSuccess;
    } else if ([resultString isEqualToString:@"FULL"]) {
        result = kMTRTCRegisterResultTypeFull;
    }
    return result;
}

@end
