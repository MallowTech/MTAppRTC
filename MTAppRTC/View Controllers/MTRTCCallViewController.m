//
//  MTRTCCallViewController.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 27/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTRTCCallViewController.h"
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCSSLAdapter.h>
#import <WebRTC/RTCConfiguration.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCAudioTrack.h>
#import <WebRTC/RTCVideoTrack.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVCaptureDevice.h>
#import "MTRTCHelper.h"

#define kServerURL @"https://appr.tc"


@interface MTRTCCallViewController ()

@end

@implementation MTRTCCallViewController

#pragma mark - View Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];

    [self customizeUI];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self initializeClientWithIceServers];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self disconnect];
    
    [super viewWillDisappear:animated];
}


#pragma mark - Custom Methods

-(void)customizeUI {
    self.isAudioOn = YES;
    self.isVideoOn = YES;
    self.audioButton.layer.cornerRadius = self.audioButton.frame.size.height / 2;
    self.videoButton.layer.cornerRadius = self.audioButton.frame.size.height / 2;
    self.endButton.layer.cornerRadius = self.audioButton.frame.size.height / 2;
}

-(void)initializeClientWithIceServers {
    NSString *key = self.callDetails.allKeys.firstObject;
    NSDictionary *dictionary = [self.callDetails objectForKey:key];
    self.roomName = [dictionary objectForKey:@"roomId"];

    self.title = self.roomName;
    RTCIceServer *iceServer = [[RTCIceServer alloc] initWithURLStrings:@[kServerURL]];
    self.client = [[MTRTCClient alloc] initWithIceServers:[NSMutableArray arrayWithObject:iceServer] andVideoCall:YES];
    
    self.client.localVideoView = self.localVideoView;
    self.client.remoteVideoView = self.remoteVideoView;
    self.client.roomId = self.roomName;
    self.client.delegate = self;
    
    [self.client startConnection];
}

- (void)disconnect {
    if (self.client) {
        [self.localVideoView renderFrame:nil];
        [self.remoteVideoView renderFrame:nil];
        [self.client stopConnection];
    }
}

#pragma mark - IBAction Methods

- (IBAction)audioButtonPressed:(id)sender {
    UIButton *audioButton = sender;
    if (!self.isAudioOn) {
        [self.client unmuteAudio];
        [audioButton setImage:[UIImage imageNamed:@"audioOn"] forState:UIControlStateNormal];
        self.isAudioOn = YES;
    } else {
        [self.client muteAudio];
        [audioButton setImage:[UIImage imageNamed:@"audioOff"] forState:UIControlStateNormal];
        self.isAudioOn = NO;
    }
}

- (IBAction)videoButtonPressed:(id)sender {
    UIButton *videoButton = sender;
    if (!self.isVideoOn) {
        [self.client unmuteVideo];
        [videoButton setImage:[UIImage imageNamed:@"videoOn"] forState:UIControlStateNormal];
        self.isVideoOn = YES;
    } else {
        [self.client muteVideo];
        [videoButton setImage:[UIImage imageNamed:@"videoOff"] forState:UIControlStateNormal];
        self.isVideoOn = NO;
    }
}

- (IBAction)endButtonPressed:(id)sender {
    [self disconnect];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)shareButtonPressed:(id)sender {
    NSMutableArray *activityItems = [NSMutableArray new];
    [activityItems addObject:[NSString stringWithFormat:@"Please use the below link to join the chat:\nhttps://appr.tc/r/app14/%@", self.roomName]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems.mutableCopy applicationActivities:nil];
    activityViewController.popoverPresentationController.sourceView = self.view;
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:activityViewController animated:YES completion:nil];
}


#pragma mark - ARDAppClientDelegate

- (void)appClient:(MTRTCClient *)client didError:(NSError *)error {
    [MTRTCHelper showAlertWithTitle:@"OOPS!!" andMessage:@"Something went wrong. Please try again" inController:self];
    [self disconnect];
}

-(void)appClient:(MTRTCClient *)client shouldDisconnect:(BOOL)shouldDisconnect {
    if (shouldDisconnect) {
        [self.localVideoView renderFrame:nil];
        [self.remoteVideoView renderFrame:nil];
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [MTRTCHelper showAlertWithTitle:@"OOPS!!" andMessage:@"Connection disconnected. Please try with another room id" inController:self];
}


@end
