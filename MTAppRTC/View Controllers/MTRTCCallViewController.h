//
//  MTRTCCallViewController.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 27/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebRTC/RTCAVFoundationVideoSource.h>
#import <WebRTC/RTCIceServer.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import "MTRTCClient.h"

@class MTRTCCallViewController;
@protocol MTRTCCallViewControllerDelegate <NSObject>
- (void)viewControllerDidFinish:(MTRTCCallViewController *)viewController;
@end

@interface MTRTCCallViewController : UIViewController <MTRTCClientDelegate>

@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *localVideoView;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *remoteVideoView;

@property (strong, nonatomic) IBOutlet UIButton *audioButton;
@property (strong, nonatomic) IBOutlet UIButton *videoButton;
@property (strong, nonatomic) IBOutlet UIButton *endButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityLoadingIndicator;

@property (strong, nonatomic) NSString *roomName;
@property (nonatomic, assign) BOOL isAudioOn;
@property (nonatomic, assign) BOOL isVideoOn;

@property (nonatomic, weak) id<MTRTCCallViewControllerDelegate> delegate;
@property (nonatomic, strong) MTRTCClient *client;

- (IBAction)audioButtonPressed:(id)sender;
- (IBAction)videoButtonPressed:(id)sender;
- (IBAction)endButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;

@end
