//
//  MTRTCRegisterResponse.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 28/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MTRTCRegisterResultType) {
    kMTRTCRegisterResultTypeUnknown,
    kMTRTCRegisterResultTypeSuccess,
    kMTRTCRegisterResultTypeFull
};

@interface MTRTCRegisterResponse : NSObject

@property(nonatomic, assign) MTRTCRegisterResultType registerResultType;
@property(nonatomic, assign) BOOL isInitiator;
@property(nonatomic, strong) NSString *roomId;
@property(nonatomic, strong) NSString *clientId;
@property(nonatomic, strong) NSArray *messages;
@property(nonatomic, strong) NSString *webSocketURLString;
@property(nonatomic, strong) NSString *webSocketRestURLString;

+ (MTRTCRegisterResponse *)responseFromJSONData:(NSData *)data;

@end
