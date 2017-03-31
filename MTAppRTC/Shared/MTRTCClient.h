//
//  MTRTCClient.h
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 27/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureSession.h>

#import <WebRTC/RTCAVFoundationVideoSource.h>
#import <WebRTC/RTCIceServer.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import <WebRTC/RTCSSLAdapter.h>
#import <WebRTC/RTCConfiguration.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCAudioTrack.h>
#import <WebRTC/RTCVideoTrack.h>

#import "MTRTCWebSocketChannel.h"
#import "MTRTCSignalingMessage.h"
#import "MTRTCRegisterResponse.h"
#import "MTRTCHelper.h"

typedef NS_ENUM(NSInteger, MTRTCClientState) {
    kMTRTCStateDisconnected,
    kMTRTCStateConnected,
    kMTRTCStateConnecting,
};

@class MTRTCClient;
@protocol MTRTCClientDelegate <NSObject>
- (void)appClient:(MTRTCClient *)client didError:(NSError *)error;
- (void)appClient:(MTRTCClient *)client shouldDisconnect:(BOOL)shouldDisconnect;
@end

@class MTRTCWebSocketChannel;
@interface MTRTCClient : NSObject

@property (nonatomic, weak) id<MTRTCClientDelegate> delegate;

@property (nonatomic, strong) RTCEAGLVideoView *localVideoView;
@property (nonatomic, strong) RTCEAGLVideoView *remoteVideoView;
@property (nonatomic, strong) NSString *roomId;

- (instancetype)initWithIceServers:(NSMutableArray<RTCIceServer *> *)iceServers andVideoCall:(BOOL)videoCall;
- (void)startConnection;
- (void)muteAudio;
- (void)unmuteAudio;
- (void)muteVideo;
- (void)unmuteVideo;
- (void)enableSpeaker;
- (void)disableSpeaker;
- (void)stopConnection;

@end
