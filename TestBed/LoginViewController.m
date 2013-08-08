//
//  ViewController.m
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [[cell textLabel] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
        
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
                [_username setPlaceholder:kEmail];
                [_username setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
                
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference] == YES) {
                    [_username setText:[[NSUserDefaults standardUserDefaults] valueForKey:kUsername]];
                    [_rememberUsername setChecked];
                }
                
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
                [_password setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
                
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
        
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    
    _rememberUsername = [[CPCheckBox alloc] initWithFrame:CGRectMake(88, 0, 210, 25)];
    [_rememberUsername setTitle:@"Automatically Login" forState:UIControlStateNormal];
    
    [_rememberUsername setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_rememberUsername setTitleShadowColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    [[_rememberUsername titleLabel] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    
    [footerView addSubview:_rememberUsername];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference] == YES) {
        [_username setText:[[NSUserDefaults standardUserDefaults] valueForKey:kUsername]];
        
        [_password setText:[SFHFKeychainUtils getPasswordForUsername:[_username text] andServiceName:kJukaelaSocialServiceName error:nil]];
        
        [_rememberUsername setChecked];
    }
    
    [tableView setTableFooterView:footerView];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tempCell setSelected:NO animated:YES];
    
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

-(void)loginAction:(id)sender
{
    [[ActivityManager sharedManager] incrementActivityCount];
    
    [[self view] findAndResignFirstResponder];
    
    NSError *error = nil;
    
    if ([_rememberUsername isChecked]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kReadUsernameFromDefaultsPreference];
        
        [SFHFKeychainUtils storeUsername:[_username text] andPassword:[_password text] forServiceName:kJukaelaSocialServiceName updateExisting:YES error:&error];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kReadUsernameFromDefaultsPreference];
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:[_username text] forKey:kUsername];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setProgressHUD:[[MBProgressHUD alloc] initWithWindow:[[self view] window]]];
    [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
    [[self progressHUD] setLabelText:@"Logging in..."];
    [[self progressHUD] setDelegate:self];
    
    [[[self view] window] addSubview:[self progressHUD]];
    
    [[self progressHUD] show:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/sessions.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory loginRequestWithEmail:[_username text] password:[_password text] apns:[[NSUserDefaults standardUserDefaults] valueForKey:kDeviceTokenPreference]];
            
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [request setTimeoutInterval:30];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            loginDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            if (loginDict) {
                for (UITabBarItem *item in [[[self tabBarController] tabBar] items]) {
                    [item setEnabled:YES];
                }

                [kAppDelegate setUserID:[NSString stringWithFormat:@"%@", loginDict[kID]]];
                [kAppDelegate setUserEmail:[NSString stringWithFormat:@"%@", loginDict[kEmail]]];
                [kAppDelegate setUserUsername:[NSString stringWithFormat:@"%@", loginDict[kUsername]]];
                
                [[NSUserDefaults standardUserDefaults] setValue:[kAppDelegate userID] forKey:kUserID];
                
                [self getFeed];
            }
            else {
                [[self progressHUD] hide:YES];
                
                UIAlertView *loginFailedAlert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"The login has failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                
                [loginFailedAlert show];
            }
        }
        else {
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [[self progressHUD] hide:YES];
            
            UIAlertView *loginFailedAlert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"The login has failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            
            [loginFailedAlert show];
        }
        
        [[ActivityManager sharedManager] decrementActivityCount];
    }];
}

-(void)getFeed
{
    [[self progressHUD] setLabelText:@"Loading Feed..."];
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory feedRequestFrom:0 to:20];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setTempFeed:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
            
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [self performSegueWithIdentifier:kShowFeed sender:self];
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
        
        [viewController setTheFeed:(NSMutableArray *)[self tempFeed]];
    }
}

-(void)viewDidLoad
{
    [kAppDelegate setCurrentViewController:self];

    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMyLove:)];
    
    [recognizer setNumberOfTapsRequired:2];
    
    [[self imageView] addGestureRecognizer:recognizer];
    
    UIWindow *tempWindow = [kAppDelegate window];
    
    if (tempWindow.frame.size.height > 500) {
        [[self imageView] setFrame:CGRectOffset(_imageView.frame, 0, 44)];
    }
        
    for (UITabBarItem *item in [[[self tabBarController] tabBar] items]) {
        [item setEnabled:NO];
    }

    [[[self imageView] layer] setShadowColor:[[UIColor blackColor] CGColor]];
    [[[self imageView] layer] setShadowOffset:CGSizeMake(0, 1)];
    [[[self imageView] layer] setShadowOpacity:0.75];
    [[[self imageView] layer] setShadowRadius:3.0];
    [[self imageView] setClipsToBounds:NO];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference] == YES) {
        [kAppDelegate setUserID:[[NSUserDefaults standardUserDefaults] valueForKey:kUserID]];

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        
        FeedViewController *feedViewController = [storyboard instantiateViewControllerWithIdentifier:@"FeedViewController"];
        
        [feedViewController setLoadedDirectly:YES];
        
        [[self navigationController] pushViewController:feedViewController animated:NO];
    }
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"new_user" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification){
        [[self username] setText:[aNotification userInfo][kEmail]];
    }];
    
    _username = [[UITextField alloc] init];
    _password = [[UITextField alloc] init];
}

-(void)showMyLove:(id)sender
{

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [kAppDelegate setCurrentViewController:self];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference] == YES) {
        if ([[self rememberUsername] isChecked] == NO) {
            [[self rememberUsername] setChecked];
        }
        if (![self doNotLogin]) {
            [self loginAction:nil];
            
            [self setDoNotLogin:NO];
        }
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
