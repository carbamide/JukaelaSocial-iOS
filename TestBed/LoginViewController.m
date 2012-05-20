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

@synthesize username;
@synthesize password;
@synthesize loginButton;
@synthesize tempFeed;
@synthesize loginTableView;
@synthesize progressHUD;
@synthesize rememberUsername;
@synthesize imageView;

-(void)customizeNavigationBar
{
    PrettyNavigationBar *navBar = (PrettyNavigationBar *)self.navigationController.navigationBar;
    
    [navBar setTopLineColor:[UIColor colorWithHex:0xafafaf]];
    [navBar setGradientStartColor:[UIColor colorWithHex:0x969696]];
    [navBar setGradientEndColor:[UIColor colorWithHex:0x3e3e3e]];
    [navBar setBottomLineColor:[UIColor colorWithHex:0x303030]];
    [navBar setTintColor:[navBar gradientEndColor]];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[self loginTableView] dequeueReusableCellWithIdentifier:@"LoginCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoginCell"];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [cell setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];  
        
        if ([indexPath section] == 0) {
            
            if ([indexPath row] == 0) {                
                [username setFrame:CGRectMake(110, 10, 150, 30)];
                [username setAdjustsFontSizeToFitWidth:YES];
                [username setTextColor:[UIColor blackColor]];
                [username setKeyboardType:UIKeyboardTypeEmailAddress];
                [username setReturnKeyType:UIReturnKeyNext];
                [username setTag:10];
                [username setBackgroundColor:[UIColor whiteColor]];
                [username setAutocorrectionType:UITextAutocorrectionTypeNo];
                [username setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [username setTextAlignment:UITextAlignmentLeft];
                [username setDelegate:self];
                [username setClearButtonMode:UITextFieldViewModeNever];
                [username setEnabled:YES];
                [username setBackgroundColor:[UIColor clearColor]];
                [username setTextAlignment:UITextAlignmentRight];
                [username setPlaceholder:@"email"];
                
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"read_username_from_defaults"] == YES) {
                    [username setText:[[NSUserDefaults standardUserDefaults] valueForKey:@"username"]];
                    [rememberUsername setChecked];
                }
                
                [username setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];             
                
                
                [cell addSubview:username];
            }
            else {                
                [password setFrame:CGRectMake(110, 10, 150, 30)];
                
                [password setAdjustsFontSizeToFitWidth:YES];
                [password setTextColor:[UIColor blackColor]];
                [password setKeyboardType:UIKeyboardTypeDefault];
                [password setReturnKeyType:UIReturnKeyDone];
                [password setSecureTextEntry:YES];
                [password setTag:20];
                [password setBackgroundColor:[UIColor whiteColor]];
                [password setAutocorrectionType:UITextAutocorrectionTypeNo];
                [password setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [password setTextAlignment:UITextAlignmentLeft];
                [password setDelegate:self];
                [password setClearButtonMode:UITextFieldViewModeNever];
                [password setEnabled:YES];
                [password setBackgroundColor:[UIColor clearColor]];
                [password setTextAlignment:UITextAlignmentRight];
                [password setPlaceholder:@"password"];
                
                [password setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];             
                
                [cell addSubview:password];
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
    
    rememberUsername = [[CPCheckBox alloc] initWithFrame:CGRectMake(45, 0, 210, 25)];
    [rememberUsername setTitle:@"Automatically Login" forState:UIControlStateNormal];
    
    [rememberUsername setTitleColor:kPerfectGreyShadow forState:UIControlStateNormal];
    [rememberUsername setTitleShadowColor:kPerfectGrey forState:UIControlStateNormal];
    
    
    [footerView addSubview:rememberUsername];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"read_username_from_defaults"] == YES) {
        [username setText:[[NSUserDefaults standardUserDefaults] valueForKey:@"username"]];
        
        [password setText:[SFHFKeychainUtils getPasswordForUsername:[username text] andServiceName:@"Jukaela Social" error:nil]];

        [rememberUsername setChecked];
    }
    
    [tableView setTableFooterView:footerView];
    
    return cell;    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath row]) {
        case 0:
            [username becomeFirstResponder];
            break;
        case 1:
            [password becomeFirstResponder];
            break;
        default:
            break;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    [loginTableView setBackgroundView:nil];
    [loginTableView setBackgroundColor:[UIColor clearColor]];
    
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
    
    if ([rememberUsername isChecked]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"read_username_from_defaults"];
        
        [SFHFKeychainUtils storeUsername:[username text] andPassword:[password text] forServiceName:@"Jukaela Social" updateExisting:YES error:&error];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"read_username_from_defaults"];
    }
        
    [[NSUserDefaults standardUserDefaults] setValue:[username text] forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setProgressHUD:[[MBProgressHUD alloc] initWithView:[self view]]];
    [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
    [[self progressHUD] setLabelText:@"Logging in..."];
    [[self progressHUD] setDelegate:self];
    
    [[self view] addSubview:[self progressHUD]];
    
    [[self progressHUD] show:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/sessions.json", kSocialURL]];
        
    NSString *requestString = [NSString stringWithFormat:@"{ \"session\": {\"email\" : \"%@\", \"password\" : \"%@\", \"apns\": \"%@\"}}", [username text], [password text], [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
        
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!data) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

            [[self progressHUD] hide:YES];
            
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                 message:@"Either the server just crapped itself or you have no internet connection.  At all." 
                                                                delegate:nil 
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil, nil];
            
            [errorAlert show];
            
            return;
        }
        loginDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
        
        if (loginDict) {
            NSLog(@"%@", loginDict);
            
            [[[[[self tabBarController] tabBar] items] objectAtIndex:1] setEnabled:YES];
            [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setEnabled:YES];

            [kAppDelegate setUserID:[NSString stringWithFormat:@"%@", [loginDict objectForKey:@"id"]]];
                        
            [self getFeed];
        }
        else {
            [[self progressHUD] hide:YES];
            
            UIAlertView *loginFailed = [[UIAlertView alloc] initWithTitle:@"Login Failed" 
                                                                  message:@"The login has failed. Sorry!" 
                                                                 delegate:nil 
                                                        cancelButtonTitle:@"OK" 
                                                        otherButtonTitles:nil, nil];
            
            [loginFailed show];
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

-(void)getFeed
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
        
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
   
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self setTempFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];

        NSLog(@"%@", tempFeed);
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [self performSegueWithIdentifier:@"ShowFeed" sender:self];
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
	if (sender == username) {
        [password becomeFirstResponder];
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
    [[[[[self tabBarController] tabBar] items] objectAtIndex:1] setEnabled:NO];
    [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setEnabled:NO];

    [[[self imageView] layer] setShadowColor:[[UIColor blackColor] CGColor]];
    [[[self imageView] layer] setShadowOffset:CGSizeMake(0, 1)];
    [[[self imageView] layer] setShadowOpacity:0.75];
    [[[self imageView] layer] setShadowRadius:3.0];
    [[self imageView] setClipsToBounds:NO];

    [super viewDidLoad];
    
    [self customizeNavigationBar];
    
    username = [[UITextField alloc] init];
    password = [[UITextField alloc] init];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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
