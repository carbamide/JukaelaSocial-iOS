//
//  NewUserViewController.m
//  Jukaela
//
//  Created by Josh on 8/26/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#import "NewUserViewController.h"

@interface NewUserViewController ()
@property (strong, nonatomic) UITextField *nameTextField;
@property (strong, nonatomic) UITextField *usernameTextField;
@property (strong, nonatomic) UITextField *emailTextField;
@property (strong, nonatomic) UITextField *passwordTextField;
@property (strong, nonatomic) UITextField *passwordConfirmTextField;

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
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(attemptToCreateUser:)]];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
    [self setNameTextField:[[UITextField alloc] init]];
    [self setUsernameTextField:[[UITextField alloc] init]];
    [self setEmailTextField:[[UITextField alloc] init]];
    [self setPasswordTextField:[[UITextField alloc] init]];
    [self setPasswordConfirmTextField:[[UITextField alloc] init]];
    
    [[self nameTextField] setFont:[UIFont fontWithName:kHelveticaLight size:16]];
    [[self usernameTextField] setFont:[UIFont fontWithName:kHelveticaLight size:16]];
    [[self emailTextField] setFont:[UIFont fontWithName:kHelveticaLight size:16]];
    [[self passwordTextField] setFont:[UIFont fontWithName:kHelveticaLight size:16]];
    [[self passwordConfirmTextField] setFont:[UIFont fontWithName:kHelveticaLight size:16]];
    
    [super viewDidLoad];
}

-(IBAction)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)attemptToCreateUser:(id)sender
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
        BlockAlertView *passwordsDontMatchAlert = [[BlockAlertView alloc] initWithTitle:@"Password" message:@"The passwords must match"];
        
        [passwordsDontMatchAlert setCancelButtonWithTitle:@"OK" block:nil];
        
        [passwordsDontMatchAlert show];
        
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory createNewUserRequestWithName:[[self nameTextField] text] username:[[self usernameTextField] text] email:[[self emailTextField] text] password:[[self passwordTextField] text] passwordConfirmation:[[self passwordConfirmTextField] text]];
        
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (data) {
            if ([[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil] isKindOfClass:[NSDictionary class]]) {
                NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]);

                [[NSNotificationCenter defaultCenter] postNotificationName:@"new_user" object:nil userInfo:@{kEmail : [[self emailTextField] text]}];
                
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:@"Error creating your new user account.  Please try again."];
                
                [errorAlert setCancelButtonWithTitle:@"OK" block:nil];
                
                [errorAlert show];
                
                [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(attemptToCreateUser:)]];
            }
        }
        else {
            BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:@"Error creating your new user account.  Please try again."];
            
            [errorAlert setCancelButtonWithTitle:@"OK" block:nil];
            
            [errorAlert show];
            
            [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(attemptToCreateUser:)]];
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
    
    [[cell textLabel] setFont:[UIFont fontWithName:kHelveticaLight size:12]];
    
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

    [cell prepareForTableView:tableView indexPath:indexPath];
    
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
