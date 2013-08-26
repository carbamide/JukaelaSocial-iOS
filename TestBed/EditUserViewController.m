//
//  EditUserViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/20/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "EditUserViewController.h"
#import "SFHFKeychainUtils.h"
#import "DataManager.h"
#import "User.h"

@interface EditUserViewController ()

-(NSArray *)fieldsArray;

@property (strong, nonatomic) UISwitch *emailSwitch;

@end

@implementation EditUserViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];
    
    [super viewDidAppear:animated];
}

-(void)getUserInfo:(NSNumber *)userID
{
    User *currentUser = [[DataManager sharedInstance] currentUser];
    
    [[self nameTextField] setText:[currentUser name]];
    
    [[self usernameTextField] setText:[currentUser username]];
    
    [[self emailTextField] setText:[currentUser email]];
    
    [[self profileTextView] setText:[currentUser profile]];
    
    [[self emailSwitch] setOn:[currentUser sendEmail]];
    
    NSError *error = nil;
    
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:[currentUser email] andServiceName:kJukaelaSocialServiceName error:&error];
    
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];

    if (password) {
        [[self passwordTextField] setText:password];
        [[self passwordConfirmTextField] setText:password];
    }
    
    if (error) {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];
        
        [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
        
        [Helpers errorAndLogout:self withMessage:@"There was an error downloading user information.  Please logout and log back in."];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
    
    [self setShowBackgroundImage:YES];
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    
    [activityView sizeToFit];
    
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin)];
    
    [activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    
    [activityView startAnimating];
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
    [[self navigationItem] setRightBarButtonItem:loadingView];
    
    [self setNameTextField:[[UITextField alloc] init]];
    [self setUsernameTextField:[[UITextField alloc] init]];
    [self setEmailTextField:[[UITextField alloc] init]];
    [self setPasswordTextField:[[UITextField alloc] init]];
    [self setPasswordConfirmTextField:[[UITextField alloc] init]];
    [self setProfileTextView:[[UITextView alloc] init]];
    
    [[self nameTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    [[self usernameTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    [[self emailTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    [[self passwordTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    [[self passwordConfirmTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    
    [[self profileTextView] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
    
    [self getUserInfo:[kAppDelegate userID]];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"updated_user" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)saveProfile:(id)sender
{
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    
    [activityView sizeToFit];
    
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin)];
    
    [activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    
    [activityView startAnimating];
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
    [[self navigationItem] setRightBarButtonItem:loadingView];
    
    if (![[[self passwordTextField] text] isEqualToString:[[self passwordConfirmTextField] text]]) {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];
        
        UIAlertView *passwordsDontMatchAlert = [[UIAlertView alloc] initWithTitle:@"Password" message:@"The passwords must match" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [passwordsDontMatchAlert show];
        
        return;
    }
    
    User *tempUser = [[DataManager sharedInstance] currentUser];
    
    [tempUser setName:[[self nameTextField] text]];
    [tempUser setUsername:[[self usernameTextField] text]];
    [tempUser setEmail:[[self emailTextField] text]];
    [tempUser setSendEmail:[[self emailSwitch] isOn]];
    [tempUser setProfile:[[self profileTextView] text]];
    
    [[ApiFactory sharedManager] updateUser:tempUser password:[[self passwordTextField] text]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self fieldsArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%d", [indexPath row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
    
    [[cell textLabel] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    
    if ([indexPath row] == 0) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self nameTextField] setTextAlignment:NSTextAlignmentRight];
        [[self nameTextField] setFrame:CGRectMake(110, 14, 185, 30)];
        [[self nameTextField] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        
        [cell addSubview:[self nameTextField]];
    }
    if ([indexPath row] == 1) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self usernameTextField] setTextAlignment:NSTextAlignmentRight];
        [[self usernameTextField] setFrame:CGRectMake(110, 11, 185, 30)];
        [[self usernameTextField] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        
        [cell addSubview:[self usernameTextField]];
    }
    if ([indexPath row] == 2) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self emailTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self emailTextField] setTextAlignment:NSTextAlignmentRight];
        [[self emailTextField] setKeyboardType:UIKeyboardTypeEmailAddress];
        [[self emailTextField] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        
        [cell addSubview:[self emailTextField]];
    }
    if ([indexPath row] == 3) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self passwordTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self passwordTextField] setTextAlignment:NSTextAlignmentRight];
        [[self passwordTextField] setSecureTextEntry:YES];
        
        [cell addSubview:[self passwordTextField]];
    }
    if ([indexPath row] == 4) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self passwordConfirmTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self passwordConfirmTextField] setTextAlignment:NSTextAlignmentRight];
        [[self passwordConfirmTextField] setSecureTextEntry:YES];
        
        [cell addSubview:[self passwordConfirmTextField]];
    }
    if ([indexPath row] == 5) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setEmailSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
        
        [cell setAccessoryView:[self emailSwitch]];
    }
    if ([indexPath row] == 6) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self profileTextView] setFrame:CGRectMake(110, 10, 195, 100)];
        [[self usernameTextField] setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
        [[self profileTextView] setBackgroundColor:[UIColor clearColor]];
        
        [cell addSubview:[self profileTextView]];
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == 6) {
        return 120;
    }
    else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tempCell setSelected:NO animated:YES];
}

-(NSArray *)fieldsArray
{
    NSArray *tempArray = @[@"Name", @"Username", @"Email", @"Password", @"Confirm", @"Email Alerts", @"Profile"];
    
    return tempArray;
}

@end
