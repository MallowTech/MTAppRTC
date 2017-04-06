//
//  MTMissedCall.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Firebase;

@interface MTMissedCall : NSObject

@property (strong, nonatomic) FIRDataSnapshot *data;
@property (nonatomic) NSInteger count;
@property (strong, nonatomic) NSString *email;

@end
