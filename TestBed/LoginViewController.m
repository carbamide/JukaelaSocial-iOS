//
//  ViewController.m
//  Jukaela Social
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "FeedViewController.h"
#import "LoginViewController.h"
#import "SFHFKeychainUtils.h"
#import "LoginImage.h"

@interface LoginViewController ()
@property (strong, nonatomic) NSArray *tempFeed;
@end

@implementation LoginViewController

-(void)loginAction:(id)sender
{
    [[ActivityManager sharedManager] incrementActivityCount];
    
    [[self view] findAndResignFirstResponder];
    
    NSError *error = nil;
    
    [SFHFKeychainUtils storeUsername:[_usernameTextField text] andPassword:[_passwordTextField text] forServiceName:kJukaelaSocialServiceName updateExisting:YES error:&error];
    
    if (error) {
        NSLog(@"There has been an error storing the password to the iOS keychain!");
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:[_usernameTextField text] forKey:kUsername];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setProgressHUD:[[MBProgressHUD alloc] initWithWindow:[[self view] window]]];
    [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
    [[self progressHUD] setLabelText:@"Logging in..."];
    [[self progressHUD] setDelegate:self];
    
    [[[self view] window] addSubview:[self progressHUD]];
    
    [[self progressHUD] show:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/sessions.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory loginRequestWithEmail:[_usernameTextField text] password:[_passwordTextField text] apns:[[NSUserDefaults standardUserDefaults] valueForKey:kDeviceTokenPreference]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest postRequestWithURL:url withData:requestData timeout:60];
    
    [request setTimeoutInterval:30];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            _loginDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            if (_loginDict) {
                [kAppDelegate setUserID:_loginDict[kID]];
                [kAppDelegate setUserEmail:_loginDict[kEmail]];
                [kAppDelegate setUserUsername:_loginDict[kUsername]];
                
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
    
    NSMutableURLRequest *request = [NSMutableURLRequest postRequestWithURL:url withData:requestData timeout:60];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setTempFeed:[ObjectMapper convertToFeedItemArray:data]];
            
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [self performSegueWithIdentifier:kShowFeed sender:self];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading your feed.  Please logout and log back in."];
        }
    }];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[[self view] findAndResignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(id)sender
{
	if (sender == _usernameTextField) {
        [_passwordTextField becomeFirstResponder];
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
        
        [viewController setTableDataSource:(NSMutableArray *)[self tempFeed]];
    }
}

-(void)loginImage
{
    if (self == [kAppDelegate currentViewController]) {
        [[ApiFactory sharedManager] loginImage];
    }
}

-(IBAction)showLoginTextFields:(id)sender
{
    if ([[self usernameTextField] alpha] == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            [[self usernameTextField] setAlpha:1.0];
            [[self passwordTextField] setAlpha:1.0];
        } completion:^(BOOL complete){
            if (complete) {
                [[self usernameTextField] becomeFirstResponder];
            }
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            [[self usernameTextField] setAlpha:0];
            [[self passwordTextField] setAlpha:0];
        }];
    }
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self usernameTextField] setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:0.3]];
    [[self passwordTextField] setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:0.3]];
    
    if (![[[self navigationController] navigationBar] isHidden]) {
        [[[self navigationController] navigationBar] setHidden:YES];
    }
    
    UIImage *image = [Helpers loginImage];
    
    [[self imageView] setImage:image];
    
    [kAppDelegate setCurrentViewController:self];
    
    [self loginImage];
    
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(loginImage)
                                   userInfo:nil
                                    repeats:YES];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference] == YES) {
        [kAppDelegate setUserID:[[NSUserDefaults standardUserDefaults] valueForKey:kUserID]];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        
        FeedViewController *feedViewController = [storyboard instantiateViewControllerWithIdentifier:@"FeedViewController"];
        
        [feedViewController setLoadedDirectly:YES];
        
        [[self navigationController] pushViewController:feedViewController animated:NO];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"new_user" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification){
        [[self usernameTextField] setText:[aNotification userInfo][kEmail]];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"image_for_login" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification){
        LoginImage *loginImageObject = [aNotification userInfo][@"login"];
        
        UIImage *image = [[loginImageObject image] applyLightEffect];
        
        [UIImage saveImage:image withFileName:@"Login"];
        dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        
        dispatch_async(aQueue, ^{
            CATransition *transition = [CATransition animation];
            
            [transition setDuration:1.0];
            [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [transition setType:kCATransitionFade];
            
            [[[self imageView] layer] addAnimation:transition forKey:nil];
            
            __block UIImage *image = [[loginImageObject image] applyLightEffect];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self changeBackgroundImage:image];
            });
        });
        
    }];
}

-(void)changeBackgroundImage:(UIImage *)anImage
{
    [[self imageView] setImage:anImage];
    
    [CATransaction commit];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSString *passwordString = [SFHFKeychainUtils getPasswordForUsername:[[NSUserDefaults standardUserDefaults] stringForKey:kUsername] andServiceName:kJukaelaSocialServiceName error:nil];
    
    if ([passwordString length] > 0) {
        [_usernameTextField setText:[[NSUserDefaults standardUserDefaults] stringForKey:kUsername]];
        [_passwordTextField setText:passwordString];
        
        [self loginAction:nil];
    }
    
    [kAppDelegate setCurrentViewController:self];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[self progressHUD] hide:YES];
}

@end
