//
//  MTRTCSignalingMessage.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 30/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCSessionDescription.h>

#import "MTRTCHelper.h"
#import "MTRTCClient.h"

typedef NS_ENUM(NSInteger, MTRTCSignalingMessageType) {
    kMTRTCSignalingMessageTypeCandidate,
    kMTRTCSignalingMessageTypeOffer,
    kMTRTCSignalingMessageTypeAnswer,
    kMTRTCSignalingMessageTypeBye,
};

@interface MTRTCSignalingMessage : NSObject

@property(nonatomic, assign) MTRTCSignalingMessageType type;
@property(nonatomic, strong) RTCIceCandidate *candidate;
@property(nonatomic, strong) RTCSessionDescription *sessionDescription;

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate;
- (instancetype)initWithDescription:(RTCSessionDescription *)description;
//- (NSString *)description;

+ (MTRTCSignalingMessage *)messageFromJSONString:(NSString *)jsonString;
- (NSData *)JSONData;

@end
