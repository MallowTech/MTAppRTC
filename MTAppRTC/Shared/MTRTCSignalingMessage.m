//
//  MTRTCSignalingMessage.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 30/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTRTCSignalingMessage.h"

static NSString const *kRTCSignalingMessageTypeKey = @"type";
static NSString const *kRTCSessionDescriptionTypeKey = @"type";
static NSString const *kRTCSessionDescriptionSdpKey = @"sdp";

@implementation MTRTCSignalingMessage

- (instancetype)initWithType:(MTRTCSignalingMessageType)type {
    if (self = [super init]) {
        self.type = type;
    }
    return self;
}

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate {
    if (self = [self initWithType:kMTRTCSignalingMessageTypeCandidate]) {
        self.candidate = candidate;
    }
    return self;
}

- (instancetype)initWithDescription:(RTCSessionDescription *)description {
    MTRTCSignalingMessageType type = kMTRTCSignalingMessageTypeOffer;
    RTCSdpType sdpType = description.type;
    if (sdpType == RTCSdpTypeOffer) {
        type = kMTRTCSignalingMessageTypeOffer;
    } else if (sdpType == RTCSdpTypeAnswer) {
        type = kMTRTCSignalingMessageTypeAnswer;
    }
    if (self = [self initWithType:type]) {
        self.sessionDescription = description;
    }
    return self;
}

//- (NSString *)description {
//    return [[NSString alloc] initWithData:[self JSONData] encoding:NSUTF8StringEncoding];
//}

+ (MTRTCSignalingMessage *)messageFromJSONString:(NSString *)jsonString {
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [MTRTCHelper dictionaryFromData:data];
    
    if (!dictionary) {
        NSLog(@"Error parsing JSON.");
        return nil;
    }
    
    NSString *typeString = dictionary[kRTCSignalingMessageTypeKey];
    MTRTCSignalingMessage *message = nil;
    if ([typeString isEqualToString:@"candidate"]) {
        RTCIceCandidate *candidate = [MTRTCHelper candidateForDictionary:dictionary];
        message = [[MTRTCSignalingMessage alloc] initWithCandidate:candidate];
    } else if ([typeString isEqualToString:@"offer"] || [typeString isEqualToString:@"answer"]) {
        RTCSdpType sdpType = [RTCSessionDescription typeForString:dictionary[kRTCSessionDescriptionTypeKey]];
        RTCSessionDescription *description = [[RTCSessionDescription alloc] initWithType:sdpType sdp:[dictionary objectForKey:kRTCSessionDescriptionSdpKey]];
        message = [[MTRTCSignalingMessage alloc] initWithDescription:description];
    } else if ([typeString isEqualToString:@"bye"]) {
        message = [[MTRTCSignalingMessage alloc] initWithType:kMTRTCSignalingMessageTypeBye];
    } else {
        message = [[MTRTCSignalingMessage alloc] init];
    }
    
    return message;
}

- (NSData *)JSONData {
    NSData *data = [[NSData alloc] init];
    if (self.type == kMTRTCSignalingMessageTypeCandidate) {
        data = [MTRTCHelper dataForCandidate:self.candidate];
    } else if ((self.type == kMTRTCSignalingMessageTypeOffer) || (self.type == kMTRTCSignalingMessageTypeAnswer)) {
        data = [MTRTCHelper dataForSessionDescription:self.sessionDescription];
    } else if (self.type == kMTRTCSignalingMessageTypeBye) {
        data = [MTRTCHelper byeData];
    }
    return data;
}

@end
