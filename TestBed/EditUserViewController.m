//
//  EditUserViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/20/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#import "EditUserViewController.h"

@interface EditUserViewController ()
-(NSArray *)fieldsArray;
@property (strong, nonatomic) NSDictionary *tempDict;
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

-(void)getUserInfo:(NSString *)userID
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, userID]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];

            [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if ([self tempDict][kName] && [self tempDict][kName] != [NSNull null]) {
                [[self nameTextField] setText:[self tempDict][kName]];
            }
            
            if ([self tempDict][kUsername] && [self tempDict][kUsername] != [NSNull null]) {
                [[self usernameTextField] setText:[self tempDict][kUsername]];
            }
            
            if ([self tempDict][kEmail] && [self tempDict][kEmail] != [NSNull null]) {
                [[self emailTextField] setText:[self tempDict][kEmail]];
            }
            
            if ([self tempDict][@"profile"] && [self tempDict][@"profile"] != [NSNull null]) {
                [[self profileTextView] setText:[self tempDict][@"profile"]];
            }
            
            if ([self tempDict][@"send_email"] && [self tempDict][@"send_email"] != [NSNull null]) {
                [[self emailSwitch] setOn:[[self tempDict][@"send_email"] boolValue]];
            }
        }
        else {
            [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];
            
            [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
            
            [Helpers errorAndLogout:self withMessage:@"There was an error downloading user information.  Please logout and log back in."];
        }
    }];
}

- (void)viewDidLoad
{
    [[self tableView] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    
    [activityView sizeToFit];
    
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin)];
    [activityView startAnimating];
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
    [[self navigationItem] setRightBarButtonItem:loadingView];
    
    [self getUserInfo:[kAppDelegate userID]];
    
    [self setNameTextField:[[UITextField alloc] init]];
    [self setUsernameTextField:[[UITextField alloc] init]];
    [self setEmailTextField:[[UITextField alloc] init]];
    [self setPasswordTextField:[[UITextField alloc] init]];
    [self setPasswordConfirmTextField:[[UITextField alloc] init]];
    [self setProfileTextView:[[UITextView alloc] init]];
    
    [[self nameTextField] setFont:[UIFont fontWithName:kFontPreference size:16]];
    [[self usernameTextField] setFont:[UIFont fontWithName:kFontPreference size:16]];
    [[self emailTextField] setFont:[UIFont fontWithName:kFontPreference size:16]];
    [[self passwordTextField] setFont:[UIFont fontWithName:kFontPreference size:16]];
    [[self passwordConfirmTextField] setFont:[UIFont fontWithName:kFontPreference size:16]];

    [[self profileTextView] setFont:[UIFont fontWithName:kFontPreference size:14]];
    
    [super viewDidLoad];
}

-(IBAction)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)saveProfile:(id)sender
{
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    
    [activityView sizeToFit];
    
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin)];
    [activityView startAnimating];
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
    [[self navigationItem] setRightBarButtonItem:loadingView];
    
    if (![[[self passwordTextField] text] isEqualToString:[[self passwordConfirmTextField] text]]) {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];

        BlockAlertView *passwordsDontMatchAlert = [[BlockAlertView alloc] initWithTitle:@"Password" message:@"The passwords must match"];
        
        [passwordsDontMatchAlert setCancelButtonWithTitle:@"OK" block:nil];
        
        [passwordsDontMatchAlert show];
        
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@", kSocialURL, [kAppDelegate userID]]];
    
    NSString *requestString = [RequestFactory editUserRequestWithName:[[self nameTextField] text] username:[[self usernameTextField] text] email:[[self emailTextField] text] password:[[self passwordTextField] text] passwordConfirmation:[[self passwordConfirmTextField] text] profile:[[self profileTextView] text] sendEmail:[NSNumber numberWithBool:[[self emailSwitch] isOn]]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (data) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];

            BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:@"Error editing your user account.  Please try again."];
            
            [errorAlert setCancelButtonWithTitle:@"OK" block:nil];
            
            [errorAlert show];
        }
    }];
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
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
    
    [[cell textLabel] setFont:[UIFont fontWithName:kFontPreference size:12]];
    
    if ([indexPath row] == 0) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self nameTextField] setFrame:CGRectMake(110, 14, 185, 30)];
        [[self nameTextField] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        
        [cell addSubview:[self nameTextField]];
    }
    if ([indexPath row] == 1) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self usernameTextField] setFrame:CGRectMake(110, 11, 185, 30)];
        [[self usernameTextField] setAutocapitalizationType:UITextAutocorrectionTypeNo];
        
        [cell addSubview:[self usernameTextField]];
    }
    if ([indexPath row] == 2) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self emailTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        
        [[self emailTextField] setKeyboardAppearance:UIKeyboardTypeEmailAddress];
        [[self emailTextField] setAutocapitalizationType:UITextAutocorrectionTypeNo];
        
        [cell addSubview:[self emailTextField]];
    }
    if ([indexPath row] == 3) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self passwordTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        
        [[self passwordTextField] setSecureTextEntry:YES];
        
        [cell addSubview:[self passwordTextField]];
    }
    if ([indexPath row] == 4) {
        [[cell textLabel] setText:[self fieldsArray][[indexPath row]]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self passwordConfirmTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        
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
        [[self profileTextView] setAutocapitalizationType:UITextAutocorrectionTypeDefault];
        [[self profileTextView] setBackgroundColor:[UIColor clearColor]];
        
        [cell addSubview:[self profileTextView]];
    }
    [cell prepareForTableView:tableView indexPath:indexPath];
    
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
