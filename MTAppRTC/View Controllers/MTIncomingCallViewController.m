//
//  MTIncomingCallViewController.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTIncomingCallViewController.h"

@interface MTIncomingCallViewController ()

@property (strong, nonatomic) IBOutlet UILabel *callInfoLabel;
@property (strong, nonatomic) IBOutlet UIButton *acceptButton;
@property (strong, nonatomic) IBOutlet UIButton *rejectButton;

@end

@implementation MTIncomingCallViewController

#pragma mark - View Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self populateDetails];
}


#pragma mark - IBAction Methods

// User rejecting the call
- (IBAction)rejectButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(rejectedCall:)]) {
        [self.delegate rejectedCall:self.callDetails];
    }
}

// User accepting the call
- (IBAction)acceptButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(acceptedCall:)]) {
        [self.delegate acceptedCall:self.callDetails];
    }
}

#pragma mark - Custom Methods

- (void)populateDetails {
    self.acceptButton.layer.cornerRadius = self.acceptButton.frame.size.height / 2;
    self.rejectButton.layer.cornerRadius = self.rejectButton.frame.size.height / 2;

    //Populate the call detail
    NSString *key = self.callDetails.allKeys.firstObject;
    NSDictionary *dictionary = [self.callDetails objectForKey:key];
    NSString *from = [dictionary objectForKey:@"from"];
    self.callInfoLabel.text = [NSString stringWithFormat:@"Call from %@", from];
}

@end
