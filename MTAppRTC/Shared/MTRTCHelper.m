//
//  MTRTCHelper.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 29/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTRTCHelper.h"

static NSString const *kRTCICECandidateTypeKey = @"type";
static NSString const *kRTCICECandidateTypeValue = @"candidate";
static NSString const *kRTCICECandidateMidKey = @"id";
static NSString const *kRTCICECandidateMLineIndexKey = @"label";
static NSString const *kRTCICECandidateSdpKey = @"candidate";
static NSString const *kRTCSessionDescriptionTypeKey = @"type";
static NSString const *kRTCSessionDescriptionSdpKey = @"sdp";
static NSString const *kRTCICEServerUsernameKey = @"username";
static NSString const *kRTCICEServerPasswordKey = @"password";
static NSString const *kRTCICEServerUrisKey = @"uris";

@implementation MTRTCHelper

//Common Send Request method
+ (void)sendAsyncRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *error))completionHandler {
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (completionHandler) {
            completionHandler(response, data, error);
        }
    }];
//    [[NSURLSession sharedSession] dataTaskWithURL:request.URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        
//    }];
}

+ (void)sendAsynchronousRequest:(NSURL *)url withData:(NSData *)data completionHandler:(void (^)(BOOL succeeded, NSData *data))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    
    [MTRTCHelper sendAsyncRequest:request completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(NO, data);
            }
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            if (completionHandler) {
                completionHandler(NO, data);
            }
            return;
        }
        if (completionHandler) {
            completionHandler(YES, data);
        }
    }];
}

//Get dictionary from Data
+ (NSDictionary *)dictionaryFromData:(NSData *)data {
    NSError *error = nil;
    NSDictionary *responseDictionary = [[NSDictionary alloc] init];
    responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:2 error:&error];
    if (error) {
        NSLog(@"Error parsing JSON: %@", error.localizedDescription);
    }
    return responseDictionary;
}

//Get Data for candidate
+ (NSData *)dataForCandidate:(RTCIceCandidate *)candidate {
    NSDictionary *json = @{ kRTCICECandidateTypeKey : kRTCICECandidateTypeValue, kRTCICECandidateMLineIndexKey : @(candidate.sdpMLineIndex), kRTCICECandidateMidKey : candidate.sdpMid, kRTCICECandidateSdpKey : candidate.sdp };
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"Error parsing JSON: %@", error);
        return nil;
    }
    return data;
}

+ (NSData *)dataForDictionary:(NSDictionary *)dictionary {
    return [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
}

+ (RTCIceCandidate *)candidateForDictionary:(NSDictionary *)dictionary {
    NSString *mid = dictionary[kRTCICECandidateMidKey];
    NSString *sdp = dictionary[kRTCICECandidateSdpKey];
    NSNumber *num = dictionary[kRTCICECandidateMLineIndexKey];
    RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:num.intValue sdpMid:mid];
    return candidate;
}

+ (NSData *)dataForSessionDescription:(RTCSessionDescription *)description {
    NSDictionary *dictionary = @{ kRTCSessionDescriptionTypeKey : [RTCSessionDescription stringForType:description.type], kRTCSessionDescriptionSdpKey : description.sdp };
    return [MTRTCHelper dataForDictionary:dictionary];
}

+ (NSArray *)serversFromCEODJSONDictionary:(NSDictionary *)dictionary {
    NSString *username = dictionary[kRTCICEServerUsernameKey];
    NSString *password = dictionary[kRTCICEServerPasswordKey];
    NSArray *uris = dictionary[kRTCICEServerUrisKey];
    NSMutableArray *servers = [NSMutableArray arrayWithCapacity:uris.count];
    RTCIceServer *server = [[RTCIceServer alloc] initWithURLStrings:servers username:username credential:password];
    [servers addObject:server];
    return servers;
}

+ (NSData *)byeData {
    NSDictionary *dictionary = @{ @"type": @"bye" };
    return [MTRTCHelper dataForDictionary:dictionary];
}

+ (NSString*)stringtoBase64:(NSString*)fromString {
    NSData *plainData = [fromString dataUsingEncoding:NSUTF8StringEncoding];
    return [plainData base64EncodedStringWithOptions:kNilOptions];
}


#pragma mark - Audio/Video Methods

+ (BOOL)isVideoDisabled {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((status == AVAuthorizationStatusRestricted) || (status == AVAuthorizationStatusDenied)) {
        return NO;
    } else {
        return YES;
    }
}

+ (BOOL)isAudioDisabled {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if ((status == AVAuthorizationStatusRestricted) || (status == AVAuthorizationStatusDenied)) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - Alert View Methods

+(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message inController:(UIViewController *)controller {
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [controller presentViewController:alert animated:true completion:nil];
}

@end
