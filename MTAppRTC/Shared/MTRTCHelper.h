//
//  MTRTCHelper.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 29/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCIceServer.h>

@interface MTRTCHelper : NSObject

+ (void)sendAsyncRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *error))completionHandler;
+ (void)sendAsynchronousRequest:(NSURL *)url withData:(NSData *)data completionHandler:(void (^)(BOOL succeeded, NSData *data))completionHandler;

+ (NSData *)dataForCandidate:(RTCIceCandidate *)candidate;
+ (NSData *)dataForDictionary:(NSDictionary *)dictionary;
+ (NSDictionary *)dictionaryFromData:(NSData *)data;
+ (RTCIceCandidate *)candidateForDictionary:(NSDictionary *)dictionary;
+ (NSData *)dataForSessionDescription:(RTCSessionDescription *)description;
+ (NSArray *)serversFromCEODJSONDictionary:(NSDictionary *)dictionary;
+ (NSData *)byeData;
+ (NSString*)stringtoBase64:(NSString*)fromString;
+ (BOOL)isVideoDisabled;
+ (BOOL)isAudioDisabled;

+(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message inController:(UIViewController *)controller;

@end
