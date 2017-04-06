//
//  MTIncomingCallViewController.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MTIncomingCallViewDelegate <NSObject>
- (void)acceptedCall:(NSDictionary *)call;
- (void)rejectedCall:(NSDictionary *)call;
@end

@interface MTIncomingCallViewController : UIViewController

@property (nonatomic, weak) id<MTIncomingCallViewDelegate> delegate;
@property (nonatomic, strong) NSDictionary *callDetails;

@end
