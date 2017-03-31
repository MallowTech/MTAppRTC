//
//  MTMainViewController.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 27/03/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTMainViewController.h"
#import "MTRTCCallViewController.h"
#import "MTRTCHelper.h"

@interface MTMainViewController ()<MTRTCCallViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *startCallButton;
@property (strong, nonatomic) IBOutlet UITextField *roomNumberTextField;

@end

@implementation MTMainViewController


#pragma mark - View Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark - IBAction Methods

- (IBAction)startCallButtonPressed:(id)sender {
    [self.view endEditing:YES];
    UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController
    if (self.roomNumberTextField.text.length < 5) {
        [MTRTCHelper showAlertWithTitle:@"OOPS!!" andMessage:@"Enter your room id with above 5 digits" inController:controller];
        return;
    } else if (![MTRTCHelper isVideoDisabled]) {
        [MTRTCHelper showAlertWithTitle:@"OOPS!!" andMessage:@"Give permssion for accessing video" inController:controller];
        return;
    } else if (![MTRTCHelper isAudioDisabled]) {
        [MTRTCHelper showAlertWithTitle:@"OOPS!!" andMessage:@"Give permssion for accessing audio" inController:controller];
        return;
    }
    [self performSegueWithIdentifier:@"MTRTCViewControllerSegue" sender:sender];
}


#pragma mark - MTRTCCallViewControllerDelegate Methods

-(void)viewControllerDidFinish:(MTRTCCallViewController *)viewController {
    [viewController dismissViewControllerAnimated:true completion:nil];
}


#pragma mark - Transition Method

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MTRTCViewControllerSegue"]) {
        MTRTCCallViewController *callViewController = (MTRTCCallViewController *)segue.destinationViewController;
        callViewController.delegate = self;
        callViewController.roomName = self.roomNumberTextField.text;
    }
}

@end
