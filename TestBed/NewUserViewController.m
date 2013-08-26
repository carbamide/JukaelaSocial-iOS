//
//  NewUserViewController.m
//  Jukaela
//
//  Created by Josh on 8/26/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//


#import "NewUserViewController.h"

@interface NewUserViewController ()
@property (strong, nonatomic) UITextField *emailTextField;
@property (strong, nonatomic) UITextField *nameTextField;
@property (strong, nonatomic) UITextField *passwordConfirmTextField;
@property (strong, nonatomic) UITextField *passwordTextField;
@property (strong, nonatomic) UITextField *usernameTextField;

-(NSArray *)fieldsArray;
@end

@implementation NewUserViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(attemptToCreateUser:)]];
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
    
    [self setShowBackgroundImage:YES];
    
    [[ActivityManager sharedManager] incrementActivityCount];
        
    [self setNameTextField:[[UITextField alloc] init]];
    [self setUsernameTextField:[[UITextField alloc] init]];
    [self setEmailTextField:[[UITextField alloc] init]];
    [self setPasswordTextField:[[UITextField alloc] init]];
    [self setPasswordConfirmTextField:[[UITextField alloc] init]];
    
    [[self nameTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    [[self usernameTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    [[self emailTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    [[self passwordTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    [[self passwordConfirmTextField] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"new_user" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)attemptToCreateUser:(id)sender
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
    
    if ([[[self passwordTextField] text] length] < 6) {
        UIAlertView *passwordTooShortAlert = [[UIAlertView alloc] initWithTitle:@"Password"
                                                                        message:@"The password you've selected is too short!  Must be 6 characters long."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil, nil];
        
        [passwordTooShortAlert show];
        
        return;
    }
    
    if (![[[self passwordTextField] text] isEqualToString:[[self passwordConfirmTextField] text]]) {
        UIAlertView *passwordsDontMatchAlert = [[UIAlertView alloc] initWithTitle:@"Password"
                                                                          message:@"The passwords must match"
                                                                         delegate:nil
                                                                cancelButtonTitle:@"OK"
                                                                otherButtonTitles:nil, nil];
        
        [passwordsDontMatchAlert show];
        
        return;
    }
    
    User *tempUser = [[User alloc] init];
    
    [tempUser setName:[[self nameTextField] text]];
    [tempUser setUsername:[[self usernameTextField] text]];
    [tempUser setEmail:[[self emailTextField] text]];

    [[ApiFactory sharedManager] createNewUser:tempUser password:[[self passwordTextField] text]];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
    
    [[cell textLabel] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    
    if ([indexPath row] == 0) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self nameTextField] setTextAlignment:NSTextAlignmentRight];
        [[self nameTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self nameTextField] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        
        [cell addSubview:[self nameTextField]];
    }
    if ([indexPath row] == 1) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self usernameTextField] setTextAlignment:NSTextAlignmentRight];
        [[self usernameTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self usernameTextField] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        
        [cell addSubview:[self usernameTextField]];
    }
    if ([indexPath row] == 2) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self emailTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self emailTextField] setTextAlignment:NSTextAlignmentRight];
        [[self emailTextField] setKeyboardType:UIKeyboardTypeEmailAddress];
        [[self usernameTextField] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        
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
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tempCell setSelected:NO animated:YES];
}

-(NSArray *)fieldsArray
{
    NSArray *tempArray = @[@"Name", @"Username", @"Email", @"Password", @"Confirm"];
    
    return tempArray;
}

@end
