//
//  MTCreateAccountViewController.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTCreateAccountViewController.h"
#import "AppDelegate.h"
#import "MTRTCHelper.h"

@interface MTCreateAccountViewController ()

@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) AppDelegate *appdelegate;

@end

@implementation MTCreateAccountViewController

#pragma mark - View Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
}


#pragma mark - IBAction Methods

- (IBAction)registerButtonPressed:(id)sender {
    [self.view endEditing:YES];
    
    if ([self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""]) {
        [MTRTCHelper showAlertWithTitle:@"OOPS!!" andMessage:@"Please fill all the fields" inController:self];
        return;
    }
    
    [self.activityIndicator startAnimating];
    [self.view setUserInteractionEnabled:false];
    [[FIRAuth auth] createUserWithEmail:self.emailTextField.text password:self.passwordTextField.text completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        if (error == nil) {
            [[[[self.appdelegate.refernce child:@"users"] child:user.uid] child:@"email"] setValue:self.emailTextField.text withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                if (error == nil) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Login"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [self.appdelegate showUsersListView];
                } else {
                    [MTRTCHelper showAlertWithTitle:@"Error!!" andMessage:error.localizedDescription inController:self];
                }
                [self.activityIndicator stopAnimating];
                [self.view setUserInteractionEnabled:true];
            }];
        } else {
            [MTRTCHelper showAlertWithTitle:@"Error!!" andMessage:error.localizedDescription inController:self];
            [self.activityIndicator stopAnimating];
            [self.view setUserInteractionEnabled:true];
        }
        
    }];
}

@end
