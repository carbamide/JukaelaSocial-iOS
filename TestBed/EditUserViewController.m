//
//  EditUserViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/20/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "EditUserViewController.h"
#import "AppDelegate.h"

@interface EditUserViewController ()
-(NSArray *)fieldsArray;
@property (strong, nonatomic) NSDictionary *tempDict;
@end

@implementation EditUserViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)getUserInfo:(NSString *)userID
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, userID]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if ([self tempDict][@"name"]) {
                [[self nameTextField] setText:[self tempDict][@"name"]];
            }
            
            if ([self tempDict][@"username"]) {
                [[self usernameTextField] setText:[self tempDict][@"username"]];
            }
            
            if ([self tempDict][@"email"]) {
                [[self emailTextField] setText:[self tempDict][@"email"]];
            }
            
            if ([self tempDict][@"profile"]) {
                [[self profileTextField] setText:[self tempDict][@"profile"]];
            }
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error downloading user information.  Please logout and log back in."];
        }
    }];
}

- (void)viewDidLoad
{
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [self getUserInfo:[kAppDelegate userID]];
    
    [self setNameTextField:[[UITextField alloc] init]];
    [self setUsernameTextField:[[UITextField alloc] init]];
    [self setEmailTextField:[[UITextField alloc] init]];
    [self setPasswordTextField:[[UITextField alloc] init]];
    [self setPasswordConfirmTextField:[[UITextField alloc] init]];
    [self setProfileTextField:[[UITextField alloc] init]];
    
    [super viewDidLoad];
}

-(IBAction)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)saveProfile:(id)sender
{
    if (![[[self passwordTextField] text] isEqualToString:[[self passwordConfirmTextField] text]]) {
        BlockAlertView *passwordsDontMatchAlert = [[BlockAlertView alloc] initWithTitle:@"Password" message:@"The passwords must match"];
        
        [passwordsDontMatchAlert setCancelButtonWithTitle:@"OK" block:nil];
        
        [passwordsDontMatchAlert show];
        
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@", kSocialURL, [kAppDelegate userID]]];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"user\": { \"name\":\"%@\",\"username\":\"%@\", \"email\":\"%@\", \"password\":\"%@\", \"password_confirmation\":\"%@\", \"profile\":\"%@\"}}", [[self nameTextField] text], [[self usernameTextField] text], [[self emailTextField] text], [[self passwordTextField] text], [[self passwordConfirmTextField] text], [[self profileTextField] text]];
    
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
            [Helpers errorAndLogout:self withMessage:@"There has been an error saving your updated user information."];
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
    
    if ([indexPath row] == 0) {
        [[cell textLabel] setText:@"Name"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self nameTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self nameTextField] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        
        [cell addSubview:[self nameTextField]];
    }
    if ([indexPath row] == 1) {
        [[cell textLabel] setText:@"Username"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self usernameTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self usernameTextField] setAutocapitalizationType:UITextAutocorrectionTypeNo];
        
        [cell addSubview:[self usernameTextField]];
    }
    if ([indexPath row] == 2) {
        [[cell textLabel] setText:@"Email"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self emailTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        
        [[self emailTextField] setKeyboardAppearance:UIKeyboardTypeEmailAddress];
        [[self emailTextField] setAutocapitalizationType:UITextAutocorrectionTypeNo];
        
        [cell addSubview:[self emailTextField]];
    }
    if ([indexPath row] == 3) {
        [[cell textLabel] setText:@"Password"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self passwordTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        
        [[self passwordTextField] setSecureTextEntry:YES];
        
        [cell addSubview:[self passwordTextField]];
    }
    if ([indexPath row] == 4) {
        [[cell textLabel] setText:@"Confirm Password"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self passwordConfirmTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        
        [[self passwordConfirmTextField] setSecureTextEntry:YES];
        
        [cell addSubview:[self passwordConfirmTextField]];
    }
    if ([indexPath row] == 5) {
        [[cell textLabel] setText:@"Profile"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[self profileTextField] setFrame:CGRectMake(110, 10, 185, 30)];
        [[self profileTextField] setAutocapitalizationType:UITextAutocorrectionTypeDefault];
        
        [cell addSubview:[self profileTextField]];
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
    NSArray *tempArray = @[@"Name", @"Username", @"Email", @"Password", @"Confirm Password", @"Profile"];
    
    return tempArray;
}

@end
