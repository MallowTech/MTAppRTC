//
//  MTRTCClient.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 27/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTRTCClient.h"

static NSString *kRTCRoomServerMessageFormat = @"%@/message/%@/%@";
static NSString *kARDRoomServerByeFormat = @"%@/leave/%@/%@";
static NSString *kServerHostURL = @"https://appr.tc";
static NSString *kStunURL = @"stun:stun.l.google.com:19302";
static NSString *kDefaultMediaConstraintKey = @"DtlsSrtpKeyAgreement";

@interface MTRTCClient () <MTRTCWebSocketChannelDelegate, RTCPeerConnectionDelegate>

@property (nonatomic, strong) NSMutableArray<RTCIceServer *> *iceServers;
@property (nonatomic, strong) NSMutableArray *messageQueue;

@property (nonatomic, strong) RTCPeerConnectionFactory *pcFactory;
@property (nonatomic, strong) RTCPeerConnection *peerConnection;

@property (nonatomic, strong) RTCVideoTrack *remoteVideoTrack;
@property (nonatomic, strong) RTCAudioTrack *remoteAudioTrack;
@property (nonatomic, strong) RTCVideoTrack *defaultVideoTrack;
@property (nonatomic, strong) RTCVideoTrack *videoTrack;
@property (nonatomic, strong) RTCAudioTrack *defaultAudioTrack;
@property (nonatomic, strong) RTCAudioTrack *audioTrack;

@property (nonatomic, assign) BOOL hasReceivedSdp;
@property (nonatomic, assign) BOOL isRegisteredWithRoomServer;
@property (nonatomic, assign) BOOL isSpeakerEnabled;
@property (nonatomic, assign) BOOL hasVideo;
@property (nonatomic, assign) BOOL isCaller;

@property (nonatomic, strong) NSString *serverHostURL;
@property (nonatomic, strong) NSString *clientId;

@property (nonatomic, strong) NSURL *webSocketURL;
@property (nonatomic, strong) NSURL *webSocketRestURL;

@property (nonatomic, strong) MTRTCWebSocketChannel *channel;

@end

@implementation MTRTCClient

#pragma mark - Initializers

- (instancetype)initWithIceServers:(NSMutableArray<RTCIceServer *> *)iceServers andVideoCall:(BOOL)videoCall {
    self = [super init];
    if (self) {
        self.hasVideo = videoCall;
        self.serverHostURL = kServerHostURL;
        self.isSpeakerEnabled = YES;
        self.messageQueue = [NSMutableArray array];
        self.iceServers = [NSMutableArray arrayWithObject:[self defaultSTUNServer]];
        [self initializePeerConnectionFactory];
    }
    return self;
}

- (void)initializePeerConnection {
    RTCConfiguration *configuration = [[RTCConfiguration alloc] init];
    configuration.iceServers = self.iceServers;
    RTCMediaConstraints *constraint = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:@{kDefaultMediaConstraintKey: @"true"}];
    self.peerConnection = [self.pcFactory peerConnectionWithConfiguration:configuration constraints:constraint delegate:self];
}

- (void)initializePeerConnectionFactory {
    [RTCPeerConnectionFactory initialize];
    self.pcFactory = [[RTCPeerConnectionFactory alloc] init];
}


#pragma mark - DeInitializers

- (void)dealloc {
    if (self.peerConnection.localStreams.firstObject != nil) {
        [self.peerConnection removeStream:self.peerConnection.localStreams.firstObject];
    }
}


#pragma mark - Custom Methods

- (RTCIceServer *)defaultSTUNServer {
    return [[RTCIceServer alloc] initWithURLStrings:@[kStunURL] username:@"" credential:@""];
}


#pragma mark - Client Methods

- (void)startConnection {    
    __weak MTRTCClient *weakSelf = self;
    
    [self registerWithServerForRoomId:self.roomId completionHandler:^(MTRTCRegisterResponse *response) {
        MTRTCClient *strongSelf = weakSelf;
        if (!response || response.registerResultType != kMTRTCRegisterResultTypeSuccess) {
            [strongSelf stopConnection];
            return;
        }
        
        self.isRegisteredWithRoomServer = YES;
        self.roomId = response.roomId;
        self.clientId = response.clientId;
        self.isCaller = response.isInitiator;
        self.webSocketURL = [NSURL URLWithString:response.webSocketURLString];
        self.webSocketRestURL = [NSURL URLWithString:response.webSocketRestURLString];
        
        for (MTRTCSignalingMessage *message in response.messages) {
            if (message.type == kMTRTCSignalingMessageTypeOffer || message.type == kMTRTCSignalingMessageTypeAnswer) {
                strongSelf.hasReceivedSdp = YES;
                [strongSelf.messageQueue insertObject:message atIndex:0];
            } else {
                [strongSelf.messageQueue addObject:message];
            }
        }
        
        [strongSelf registerWithCollider];
        [strongSelf startProducingSignals];
    }];
}

- (void)answerForCall {
    [self processMessageQueue];
}

- (void)stopConnection {
    [self.peerConnection close];
    if (self.peerConnection.localStreams.firstObject != nil) {
        [self.peerConnection removeStream:self.peerConnection.localStreams.firstObject];
    }
    
    //Check if this condition is required
    if (self.isRegisteredWithRoomServer) {
        [self unregisterWithRoomServer];
    }
    if (self.channel) {
        if (self.channel.state == kMTRTCWebSocketChannelStateRegistered) {
            // Tell the other client we're hanging up.
            NSData *byeData = [MTRTCHelper byeData];
            [self.channel sendData:byeData];
        }
        // Disconnect from collider.
        self.channel = nil;
    }
    self.clientId = nil;
    self.roomId = nil;
    self.isCaller = NO;
    self.hasReceivedSdp = NO;
    self.messageQueue = [NSMutableArray array];
    self.peerConnection = nil;
    self.remoteVideoTrack = nil;
    [self.delegate appClient:self shouldDisconnect:YES];
}

- (void)generateOffer {
    [self.peerConnection offerForConstraints:[self fetchMediaConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if ((error != nil) || ([error isKindOfClass:[NSNull class]])) {
            [self.delegate appClient:self didError:error];
        } else {
            [self handleSDPGenerated:sdp];
        }
    }];
}

- (void)processMessageQueue {
    if (!self.peerConnection || !self.hasReceivedSdp) {
        return;
    }
    for (MTRTCSignalingMessage *message in self.messageQueue) {
        [self processSignalingMessage:message];
    }
    [self.messageQueue removeAllObjects];
}


#pragma mark - Registration Methods

- (void)registerWithServerForRoomId:(NSString *)roomId completionHandler:(void (^)(MTRTCRegisterResponse *))completionHandler {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/join/%@", self.serverHostURL, roomId]];
    [MTRTCHelper sendAsynchronousRequest:url withData:nil completionHandler:^(BOOL succeeded, NSData *data) {
        if (!succeeded) {
            //error delegate
            completionHandler(nil);
            return;
        }
        
        MTRTCRegisterResponse *response = [MTRTCRegisterResponse responseFromJSONData:data];
        completionHandler(response);
    }];
}

- (void)registerWithCollider {
    if (!self.isRegisteredWithRoomServer) {
        return;
    }
    
    // Open WebSocket connection.
    self.channel = [[MTRTCWebSocketChannel alloc] initWithURL: self.webSocketURL restURL:self.webSocketRestURL delegate:self];
    [self.channel registerForRoomId:self.roomId clientId:self.clientId];
}

- (void)unregisterWithRoomServer {
    NSString *urlString =
    [NSString stringWithFormat:kARDRoomServerByeFormat, self.serverHostURL, self.roomId, self.clientId];
    NSURL *url = [NSURL URLWithString:urlString];
    //Make sure to do a POST
    [MTRTCHelper sendAsynchronousRequest:url withData:nil completionHandler:^(BOOL succeeded, NSData *data) {
        if (succeeded) {
            NSLog(@"Unregistered from room server.");
        } else {
            NSLog(@"Failed to unregister from room server.");
        }
    }];
}

#pragma mark - Media Stream Methods

- (RTCMediaStream *)generateMediaStream {
    RTCPeerConnectionFactory *factory = self.pcFactory;
    RTCMediaStream *localStream = [factory mediaStreamWithStreamId:@"ARDAMS"];
    
    // Video Track Generate
    RTCVideoTrack *localVideoTrack = [self generateLocalVideoTrack];
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        self.videoTrack = localVideoTrack;
        [self.videoTrack addRenderer:self.localVideoView];
    }
    
    // Audio Track Generate
    RTCAudioTrack *audioTrack = [self generateAudioTrack:@"ARDAMSa0"];
    [localStream addAudioTrack:audioTrack];
    if (self.isSpeakerEnabled) {
        [self enableSpeaker];
    }
    
    return localStream;
}

- (RTCMediaConstraints *)fetchMediaConstraints {
    NSDictionary *rtcMediaConstraints;
    if (self.hasVideo) {
        rtcMediaConstraints = @{@"OfferToReceiveAudio" : kRTCMediaConstraintsValueTrue, @"OfferToReceiveVideo" : kRTCMediaConstraintsValueTrue};
    } else {
        rtcMediaConstraints = @{@"OfferToReceiveAudio" : kRTCMediaConstraintsValueTrue};
    }
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:rtcMediaConstraints optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)answerMediaConstraints {
    NSDictionary *rtcMediaConstraints;
    if (self.hasVideo) {
        rtcMediaConstraints = @{@"OfferToReceiveAudio" : kRTCMediaConstraintsValueTrue, @"OfferToReceiveVideo" : kRTCMediaConstraintsValueTrue};
    } else {
        rtcMediaConstraints = @{@"OfferToReceiveAudio" : kRTCMediaConstraintsValueTrue};
    }
    NSDictionary *optionalconstraints = @{kRTCMediaConstraintsMinWidth : [MTRTCHelper stringtoBase64:@"100"], kRTCMediaConstraintsMinHeight: [MTRTCHelper stringtoBase64:@"100"], kRTCMediaConstraintsMaxWidth : [MTRTCHelper stringtoBase64:@"480"], kRTCMediaConstraintsMaxHeight: [MTRTCHelper stringtoBase64:@"640"], kRTCMediaConstraintsMinFrameRate : [MTRTCHelper stringtoBase64:@"24"], kRTCMediaConstraintsMaxFrameRate : [MTRTCHelper stringtoBase64:@"30"]};

    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:rtcMediaConstraints optionalConstraints:optionalconstraints];
    return constraints;
}

- (RTCMediaConstraints *)defaultMediaConstraints {
    RTCMediaConstraints *mediaConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    return mediaConstraints;
}


#pragma mark - Media Track Methods

- (RTCAudioTrack *)generateAudioTrack:(NSString *)trackId {
    RTCAudioTrack *audioTrack = [self.pcFactory audioTrackWithTrackId:trackId];
    return audioTrack;
}

- (RTCVideoTrack *)generateLocalVideoTrack {
    AVCaptureDevice *device;
    NSArray<AVCaptureDevice*> *captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *captureDevice in captureDevices) {
        if (captureDevice.position == AVCaptureDevicePositionFront) {
            device = captureDevice;
            break;
        }
    }
    
    // Check whetther device is detected or not for getting the video stream
    if (device) {
        RTCAVFoundationVideoSource *source = [self.pcFactory avFoundationVideoSourceWithConstraints:[self defaultMediaConstraints]];
        [source adaptOutputFormatToWidth:480 height:640 fps:24];
        RTCVideoTrack *videoTrack = [self.pcFactory videoTrackWithSource:source trackId:@"ARDAMSv0"];
        return videoTrack;
    }
    return nil;
}

#pragma mark - Receiver(Handler) Methods

- (void)createAnswerForOfferReceived:(RTCSessionDescription *)sessionDescription1 {
    if (self.peerConnection.signalingState == RTCSignalingStateHaveLocalOffer) {
        [self.peerConnection offerForConstraints:[self answerMediaConstraints] completionHandler:nil];
    } else if (self.peerConnection.signalingState == RTCSignalingStateHaveRemoteOffer) {
        [self.peerConnection answerForConstraints:[self answerMediaConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            if (error != nil) {
                [self.delegate appClient:self didError:error];
            } else {
                [self handleSDPGenerated:sdp];
            }
        }];
    }
}

- (void)handleSDPGenerated:(RTCSessionDescription *)sdpDescription {
    __weak MTRTCClient *weakSelf = self;
    RTCSessionDescription *session = [[RTCSessionDescription alloc] initWithType:sdpDescription.type sdp:sdpDescription.sdp];
    [self.peerConnection setLocalDescription:session completionHandler:^(NSError * _Nullable error) {
        MTRTCClient *strongSelf = weakSelf;
        MTRTCSignalingMessage *message = [[MTRTCSignalingMessage alloc] initWithDescription:session];
        [strongSelf sendSignalingMessage:message];
    }];
}


#pragma mark - Signal Methods

- (void)startProducingSignals {
    [self initializePeerConnection];
    RTCMediaStream *localStream = [self generateMediaStream];
    [self.peerConnection addStream:localStream];
    
    if (self.isCaller) {
        [self generateOffer];
    } else {
        [self answerForCall];
    }
}

- (void)sendSignalingMessage:(MTRTCSignalingMessage *)message {
    if (self.isCaller) {
        [self sendSignalingMessageToRoomServer:message completionHandler:nil];
    } else {
        [self sendSignalingMessageToCollider:message];
    }
}

- (void)sendSignalingMessageToRoomServer:(MTRTCSignalingMessage *)message completionHandler:(void (^)(NSString *))completionHandler {
    NSData *data = [message JSONData];
    NSString *urlString = [NSString stringWithFormat: kRTCRoomServerMessageFormat, self.serverHostURL, self.roomId, self.clientId];
    NSURL *url = [NSURL URLWithString:urlString];
    [MTRTCHelper sendAsynchronousRequest:url withData:data completionHandler:^(BOOL succeeded, NSData *data) {
        if (!succeeded) {
            if (completionHandler) {
                completionHandler(@"Something went wrong. Please try again later.");
            }
            return;
        }
        if (completionHandler) {
            completionHandler(@"Signal sent");
        }
    }];
}

- (void)processSignalingMessage:(MTRTCSignalingMessage *)message {
    switch (message.type) {
        case kMTRTCSignalingMessageTypeOffer:
        case kMTRTCSignalingMessageTypeAnswer: {
            MTRTCSignalingMessage *sdpMessage = (MTRTCSignalingMessage *)message;
            RTCSessionDescription *description = sdpMessage.sessionDescription;
            __weak MTRTCClient *weakSelf = self;
            [self.peerConnection setRemoteDescription:description completionHandler:^(NSError * _Nullable error) {
                MTRTCClient *strongSelf = weakSelf;
                [strongSelf createAnswerForOfferReceived:description];
            }];
            break;
        }
        case kMTRTCSignalingMessageTypeCandidate: {
            MTRTCSignalingMessage *candidateMessage = (MTRTCSignalingMessage *)message;
            [self.peerConnection addIceCandidate:candidateMessage.candidate];
            break;
        }
        case kMTRTCSignalingMessageTypeBye:
            [self stopConnection];
            [self.delegate appClient:self shouldDisconnect:YES];
            break;
    }
}

- (void)sendSignalingMessageToCollider:(MTRTCSignalingMessage *)message {
    NSData *data = [message JSONData];
    [self.channel sendData:data];
}


#pragma mark - ARDWebSocketChannelDelegate

- (void)channel:(MTRTCWebSocketChannel *)channel didReceiveMessage:(MTRTCSignalingMessage *)message {
    switch (message.type) {
        case kMTRTCSignalingMessageTypeOffer:
        case kMTRTCSignalingMessageTypeAnswer:
            self.hasReceivedSdp = YES;
            [self.messageQueue insertObject:message atIndex:0];
            break;
        case kMTRTCSignalingMessageTypeCandidate:
            [self.messageQueue addObject:message];
            break;
        case kMTRTCSignalingMessageTypeBye:
            [self processSignalingMessage:message];
            return;
    }
    [self processMessageQueue];
}

- (void)channel:(MTRTCWebSocketChannel *)channel didChangeState:(MTRTCWebSocketChannelState)state {
    switch (state) {
        case kMTRTCWebSocketChannelStateOpen:
            break;
        case kMTRTCWebSocketChannelStateRegistered:
            break;
        case kMTRTCWebSocketChannelStateClosed:
        case kMTRTCWebSocketChannelStateError:
            [self stopConnection];
            break;
    }
}


#pragma mark - Audio methods

- (void)muteAudio {
    RTCMediaStream *localStream = self.peerConnection.localStreams.firstObject;
    self.defaultAudioTrack = localStream.audioTracks.firstObject;
    [localStream removeAudioTrack:localStream.audioTracks.firstObject];
    [self.peerConnection removeStream:localStream];
    [self.peerConnection addStream:localStream];
}
- (void)unmuteAudio {
    RTCMediaStream* localStream = self.peerConnection.localStreams.firstObject;
    [localStream addAudioTrack:self.defaultAudioTrack];
    [self.peerConnection removeStream:localStream];
    [self.peerConnection addStream:localStream];
    if (self.isSpeakerEnabled) {
        [self enableSpeaker];
    }
}

- (void)enableSpeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    self.isSpeakerEnabled = YES;
}

- (void)disableSpeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    self.isSpeakerEnabled = NO;
}


#pragma mark - Video Methods

- (void)muteVideo {
    RTCMediaStream *localStream = self.peerConnection.localStreams.firstObject;
    self.defaultVideoTrack = localStream.videoTracks.firstObject;
    [localStream removeVideoTrack:localStream.videoTracks.firstObject];
    [self.peerConnection removeStream:localStream];
    [self.peerConnection addStream:localStream];
}
- (void)unmuteVideo {
    RTCMediaStream* localStream = self.peerConnection.localStreams.firstObject;
    [localStream addVideoTrack:self.defaultVideoTrack];
    [self.peerConnection removeStream:localStream];
    [self.peerConnection addStream:localStream];
}


#pragma mark - RTCPeerConnectionDelegate Methods

- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream {
    if (stream.videoTracks.count > 0) {
        self.remoteVideoTrack = stream.videoTracks.firstObject;
        self.remoteAudioTrack = stream.audioTracks.firstObject;
        [self.remoteVideoTrack addRenderer:self.remoteVideoView];
        if (self.isSpeakerEnabled) {
            [self enableSpeaker];
        }
    }
}

- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
    NSLog(@"PeerConnectionShouldNegotiate");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream {
    [self.remoteVideoTrack removeRenderer:self.remoteVideoView];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel {
    NSLog(@"PeerConnection didOpenDataChannel");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"PeerConnection didRemoveIceCandidates");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    NSLog(@"PeerConnection didChangeSignalingState");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    dispatch_async(dispatch_get_main_queue(), ^{
        MTRTCSignalingMessage *message = [[MTRTCSignalingMessage alloc] initWithCandidate:candidate];
        [self.peerConnection addIceCandidate:candidate];
        [self sendSignalingMessage:message];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    NSLog(@"PeerConnection didChangeIceGatheringState");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"PeerConnection didChangeIceConnectionState");
}

@end
