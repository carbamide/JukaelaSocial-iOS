//
//  ViewController.m
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#import "FeedViewController.h"
#import "LoginViewController.h"
#import "SFHFKeychainUtils.h"
#import "UIView+FindAndResignFirstResponder.h"

@interface LoginViewController ()
@property (strong, nonatomic) NSArray *tempFeed;
@end

@implementation LoginViewController

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell setTableViewBackgroundColor:[tableView backgroundColor]];
        
        if ([indexPath section] == 0) {
            
            if ([indexPath row] == 0) {                
                [_username setFrame:CGRectMake(110, 10, 185, 30)];
                [_username setAdjustsFontSizeToFitWidth:YES];
                [_username setTextColor:[UIColor blackColor]];
                [_username setKeyboardType:UIKeyboardTypeEmailAddress];
                [_username setReturnKeyType:UIReturnKeyNext];
                [_username setTag:10];
                [_username setBackgroundColor:[UIColor whiteColor]];
                [_username setAutocorrectionType:UITextAutocorrectionTypeNo];
                [_username setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [_username setTextAlignment:NSTextAlignmentLeft];
                [_username setDelegate:self];
                [_username setClearButtonMode:UITextFieldViewModeNever];
                [_username setEnabled:YES];
                [_username setBackgroundColor:[UIColor clearColor]];
                [_username setTextAlignment:NSTextAlignmentRight];
                [_username setPlaceholder:@"email"];
                
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"read_username_from_defaults"] == YES) {
                    [_username setText:[[NSUserDefaults standardUserDefaults] valueForKey:@"username"]];
                    [_rememberUsername setChecked];
                }
                
                [_username setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];             
                
                
                [cell addSubview:_username];
            }
            else {                
                [_password setFrame:CGRectMake(110, 10, 185, 30)];
                
                [_password setAdjustsFontSizeToFitWidth:YES];
                [_password setTextColor:[UIColor blackColor]];
                [_password setKeyboardType:UIKeyboardTypeDefault];
                [_password setReturnKeyType:UIReturnKeyDone];
                [_password setSecureTextEntry:YES];
                [_password setTag:20];
                [_password setBackgroundColor:[UIColor whiteColor]];
                [_password setAutocorrectionType:UITextAutocorrectionTypeNo];
                [_password setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [_password setTextAlignment:NSTextAlignmentLeft];
                [_password setDelegate:self];
                [_password setClearButtonMode:UITextFieldViewModeNever];
                [_password setEnabled:YES];
                [_password setBackgroundColor:[UIColor clearColor]];
                [_password setTextAlignment:NSTextAlignmentRight];
                [_password setPlaceholder:@"password"];
                
                [_password setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];             
                
                [cell addSubview:_password];
            }       
        }
    }
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Email"];
        }
        else {
            [[cell textLabel] setText:@"Password"];
        }
    }
    
    [cell prepareForTableView:tableView indexPath:indexPath];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    
    _rememberUsername = [[CPCheckBox alloc] initWithFrame:CGRectMake(68, 0, 210, 25)];
    [_rememberUsername setTitle:@"Automatically Login" forState:UIControlStateNormal];
    
    [_rememberUsername setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_rememberUsername setTitleShadowColor:kPerfectGrey forState:UIControlStateNormal];
    
    
    [footerView addSubview:_rememberUsername];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"read_username_from_defaults"] == YES) {
        [_username setText:[[NSUserDefaults standardUserDefaults] valueForKey:@"username"]];
        
        [_password setText:[SFHFKeychainUtils getPasswordForUsername:[_username text] andServiceName:@"Jukaela Social" error:nil]];
        
        [_rememberUsername setChecked];
    }
    
    [tableView setTableFooterView:footerView];
    
    return cell;    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath row]) {
        case 0:
            [_username becomeFirstResponder];
            break;
        case 1:
            [_password becomeFirstResponder];
            break;
        default:
            break;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    [_loginTableView setBackgroundView:nil];
    [_loginTableView setBackgroundColor:[UIColor clearColor]];
    
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

-(IBAction)loginAction:(id)sender
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [[self view] findAndResignFirstResponder];
    
    NSError *error = nil;
    
    if ([_rememberUsername isChecked]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"read_username_from_defaults"];
        
        [SFHFKeychainUtils storeUsername:[_username text] andPassword:[_password text] forServiceName:@"Jukaela Social" updateExisting:YES error:&error];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"read_username_from_defaults"];
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:[_username text] forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setProgressHUD:[[MBProgressHUD alloc] initWithView:[self view]]];
    [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
    [[self progressHUD] setLabelText:@"Logging in..."];
    [[self progressHUD] setDelegate:self];
    
    [[self view] addSubview:[self progressHUD]];
    
    [[self progressHUD] show:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/sessions.json", kSocialURL]];
    
    NSString *requestString = [NSString stringWithFormat:@"{ \"session\": {\"email\" : \"%@\", \"password\" : \"%@\", \"apns\": \"%@\"}}", [_username text], [_password text], [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!data) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [[self progressHUD] hide:YES];
            
            BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:@"Unable to login"];
            
            [errorAlert setCancelButtonWithTitle:@"OK" block:nil];
            
            [errorAlert show];
            
            return;
        }
        loginDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
        
        if (loginDict) {
            [[[[self tabBarController] tabBar] items][1] setEnabled:YES];
            [[[[self tabBarController] tabBar] items][2] setEnabled:YES];
            
            [kAppDelegate setUserID:[NSString stringWithFormat:@"%@", loginDict[@"id"]]];
            
            [self getFeed];
        }
        else {
            [[self progressHUD] hide:YES];
            
            BlockAlertView *loginFailedAlert = [[BlockAlertView alloc] initWithTitle:@"Login Failed" message:@"The login has failed. Sorry!"];
            
            [loginFailedAlert setCancelButtonWithTitle:@"OK" block:nil];
            
            [loginFailedAlert show];
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

-(void)getFeed
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setTempFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self performSegueWithIdentifier:@"ShowFeed" sender:self];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading your feed.  Please logout and log back in."];
        }
    }];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [Helpers moveViewUpFromTextField:textField withView:[self view]];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[[self view] findAndResignFirstResponder];
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [Helpers moveViewDown:[self view]];
}

-(BOOL)textFieldShouldReturn:(id)sender
{
	if (sender == _username) {
        [_password becomeFirstResponder];
        return NO;
    }
    else {
        [self loginAction:nil];
        return NO;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowFeed"]) {
        FeedViewController *viewController = [segue destinationViewController];
        
        [viewController setTheFeed:[self tempFeed]];
    }
}
-(void)viewDidLoad
{
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMyLove:)];
    
    [recognizer setNumberOfTapsRequired:2];
    
    [[self imageView] addGestureRecognizer:recognizer];
    
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];  

    [[[[self tabBarController] tabBar] items][1] setEnabled:NO];
    [[[[self tabBarController] tabBar] items][2] setEnabled:NO];
    
    [[[self imageView] layer] setShadowColor:[[UIColor blackColor] CGColor]];
    [[[self imageView] layer] setShadowOffset:CGSizeMake(0, 1)];
    [[[self imageView] layer] setShadowOpacity:0.75];
    [[[self imageView] layer] setShadowRadius:3.0];
    [[self imageView] setClipsToBounds:NO];
    
    [super viewDidLoad];
        
    _username = [[UITextField alloc] init];
    _password = [[UITextField alloc] init];
}

-(void)showMyLove:(id)sender
{
    BlockAlertView *alert = [[BlockAlertView alloc] initWithTitle:@"My Love" message:@"This app was inspired by my wife Candice. She's the most beautiful, caring, lovely woman that I've ever known. She is my inspiration, she is my heart and I wouldn't be the person that I am if it weren't for her.  Candice, I love you."];
    
    [alert setCancelButtonWithTitle:@"OK" block:nil];
    
    [alert show];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [kAppDelegate setCurrentViewController:self];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"read_username_from_defaults"] == YES) {
        if ([[self rememberUsername] isChecked] == NO) {
            [[self rememberUsername] setChecked];
        }        
        [self loginAction:nil];
    }
    else {
        if ([[self rememberUsername] isChecked] == YES) {
            [[self rememberUsername] setChecked];
        }
        
        [[self password] setText:nil];
    }
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[self progressHUD] hide:YES];
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

@end
