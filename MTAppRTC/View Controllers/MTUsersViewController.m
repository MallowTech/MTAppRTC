//
//  MTUsersViewController.m
//  MTAppRTC
//
//  Created by Yogesh Murugesh on 06/04/17.
//  Copyright © 2017 Yogesh Murugesh. All rights reserved.
//

#import "MTUsersViewController.h"
#import "AppDelegate.h"
#import "MTMissedCall.h"
#import "MTUsersManager.h"
#import "MTCallManager.h"
#import "MTRTCHelper.h"

@interface MTUsersViewController ()<UITableViewDataSource, UITableViewDelegate, MTUsersManagerDelegate>

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (strong, nonatomic) IBOutlet UITableView *tablView;

@property (strong, nonatomic) NSMutableArray *usersListArray;
@property (strong, nonatomic) NSMutableArray<MTMissedCall *> *missedCallArray;
@property (strong, nonatomic) AppDelegate *appdelegate;
@property (strong, nonatomic) MTUsersManager *usersManager;


@end

@implementation MTUsersViewController

#pragma mark - View Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.tablView.tableFooterView = [[UIView alloc] init];
    
    // Init users manager for getting the users list and missed call list
    self.usersManager = [MTUsersManager sharedManager];
    self.usersManager.delegate = self;
    
    //Fetch the users list
    [self fetchAllusers];
    //Fetch the missed call list
    [self fetchMissedCalls];
}


#pragma mark - IBAction Methods

//Based on selected segment fetch the users list from server
- (IBAction)segmentValueChanged:(id)sender {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        [self fetchAllusers];
    } else {
        [self fetchMissedCalls];
    }
    [self.tablView reloadData];
}

//User logout
- (IBAction)logoutButtonPressed:(id)sender {
    [self.appdelegate logout];
}

//Refresh the list from server
- (IBAction)refreshButtonPressed:(id)sender {
    [self segmentValueChanged:self.segmentControl];
}


#pragma mark - Custom Methods

- (void)fetchAllusers {
    [self.usersManager fetchUsers];
}

- (void)fetchMissedCalls {
    [self.usersManager fetchMissedCalls];
}

- (void)startCall:(NSString *)to {
    [[MTCallManager sharedManager] startCall:to];
}


#pragma mark - TableView Datasource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        return self.usersListArray.count == 0 ? 1 : self.usersListArray.count;//Show info text if there is no users. So we need additional row here
    } else {
        return self.missedCallArray.count ==0 ? 1: self.missedCallArray.count;//Show info text if there is no users. So we need additional row here
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    NSString *value;
    if (self.segmentControl.selectedSegmentIndex == 0) {
        if (self.usersListArray.count == 0) {
            value = @"No Users";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        } else {
            FIRDataSnapshot *child = self.usersListArray[indexPath.row];
            value = child.value[@"email"];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
        }
        cell.textLabel.textColor = [UIColor blackColor];
    } else {
        if (self.missedCallArray.count == 0) {
            value = @"No Missed calls";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        } else {
            MTMissedCall *missedCall = self.missedCallArray[indexPath.row];
            value = [NSString stringWithFormat:@"%@ (%ld)", missedCall.email, (long)missedCall.count];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
        }
        cell.textLabel.textColor = [UIColor redColor];
    }
    cell.textLabel.text = value;
    return cell;
}


#pragma mark - TableView Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *email;
    if (self.segmentControl.selectedSegmentIndex == 0) {
        FIRDataSnapshot *child = self.usersListArray[indexPath.row];
        email = child.value[@"email"];
    } else {
        MTMissedCall *missedCall = self.missedCallArray[indexPath.row];
        email = missedCall.email;
    }
    [self startCall:email];
}


#pragma mark - UserManager Methods

- (void)usersList:(NSMutableArray *)users error:(NSError *)error {
    if (error != nil) {
        [MTRTCHelper showAlertWithTitle:@"Error!!" andMessage:error.localizedDescription inController:self];
    }
    self.usersListArray = users;
    [self.tablView reloadData];
}

- (void)missedCallList:(NSMutableArray *)missedCalls error:(NSError *)error {
    if (error != nil) {
        [MTRTCHelper showAlertWithTitle:@"Error!!" andMessage:error.localizedDescription inController:self];
    }
    self.missedCallArray = missedCalls;
    [self.tablView reloadData];
}


@end
