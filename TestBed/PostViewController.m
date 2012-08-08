//
//  PostViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/16/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#import "PostViewController.h"
#import "NSString+BackslashEscape.h"
#import <Accounts/Accounts.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_1
#import <Social/Social.h>
#endif
#import <Twitter/Twitter.h>
#import "UIAlertView+Blocks.h"

@interface PostViewController ()
@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccount *facebookAccount;
@end

@implementation PostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self setupNavbarForPosting];
}

-(void)viewDidAppear:(BOOL)animated
{
    if (_replyString) {
        _theTextView = [[YIPopupTextView alloc] initWithText:[self replyString] maxCount:140];
    }
    else if (_repostString) {
        _theTextView = [[YIPopupTextView alloc] initWithText:[self repostString] maxCount:140];
    }
    else {
        _theTextView = [[YIPopupTextView alloc] initWithPlaceHolder:@"Make a post, you guys!" maxCount:140];
    }
    
    [_theTextView setDelegate:self];
    [_theTextView setShowCloseButton:NO];
    
    [_theTextView showInView:[self view]];
}

-(void)setupNavbarForPosting
{
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendPost:)];
    
    [[self navigationItem] setRightBarButtonItem:sendButton];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPost:)];
    
    [[self navigationItem] setLeftBarButtonItem:cancelButton];
}

-(void)cancelPost:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)sendPost:(id)sender
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"confirm_post"]) {
        RIButtonItem *confirmButton = [RIButtonItem itemWithLabel:@"Do it!"];
        RIButtonItem *jukaelaButton = [RIButtonItem itemWithLabel:@"Just to Jukaela!"];
        RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:@"Cancel"];
        
        [confirmButton setAction:^{
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
                [self sendTweet:[[self theTextView] text]];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
                [self sendFacebookPost:[[self theTextView] text]];
            }
            
            [self sendJukaelaPost];
        }];
        
        [jukaelaButton setAction:^{
            [self sendJukaelaPost];
        }];
        
        [cancelButton setAction:^{
            return;
        }];
        
        UIAlertView *confirmAlert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Confirm sending to other services?" cancelButtonItem:cancelButton otherButtonItems:confirmButton, jukaelaButton, nil];
        
        [confirmAlert show];
    }
    else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
            [self sendTweet:[[self theTextView] text]];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
            [self sendFacebookPost:[[self theTextView] text]];
        }
        
        [self sendJukaelaPost];
    }
    
    
}

-(void)sendJukaelaPost
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"set_change_type" object:@0];
    
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
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts.json", kSocialURL]];
    
    NSString *stringToSendAsContent = [[[self theTextView] text] stringWithSlashEscapes];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", stringToSendAsContent, [kAppDelegate userID]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"jukaela_successful" object:nil];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            UIAlertView *jukaelaSocialPostingError = [[UIAlertView alloc] initWithTitle:@"Oh No!"
                                                                                message:@"There has been an error posting to Jukaela Social."
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil, nil];
            
            [jukaelaSocialPostingError show];
        }
    }];
}

- (void)sendTweet:(NSString *)stringToSend
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            
            if ([accountsArray count] > 0) {
                ACAccount *twitterAccount = accountsArray[0];
                
                TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] parameters:@{@"status": stringToSend} requestMethod:TWRequestMethodPOST];
                
                [postRequest setAccount:twitterAccount];
                
                [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    if (responseData) {
                        NSLog(@"Successfully posted to Twitter");
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"tweet_successful" object:nil];
                    }
                    else {
                        UIAlertView *twitterPostingError = [[UIAlertView alloc] initWithTitle:@"Oh No!"
                                                                                      message:@"There has been an error posting your Jukaela Social post to Twitter."
                                                                                     delegate:nil
                                                                            cancelButtonTitle:@"OK"
                                                                            otherButtonTitles:nil, nil];
                        
                        [twitterPostingError show];
                    }
                }];
            }
        }
    }];
}

- (void)sendFacebookPost:(NSString *)stringToSend
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        if (NSStringFromClass([SLRequest class])) {
            if (_accountStore == nil) {
                _accountStore = [[ACAccountStore alloc] init];
            }
            
            ACAccountType *accountTypeFacebook = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
            
            NSDictionary *options = @{ACFacebookAppIdKey:@"493749340639998", ACFacebookAudienceKey: ACFacebookAudienceEveryone, ACFacebookPermissionsKey: @[@"publish_stream", @"publish_actions"]};
            
            [_accountStore requestAccessToAccountsWithType:accountTypeFacebook options:options completion:^(BOOL granted, NSError *error) {
                if(granted) {
                    NSArray *accounts = [self.accountStore accountsWithAccountType:accountTypeFacebook];
                    
                    [self setFacebookAccount:[accounts lastObject]];
                    
                    NSDictionary *parameters = @{@"access_token":[[[self facebookAccount] credential] oauthToken], @"message":stringToSend};
                    NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
                    
                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
                    
                    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *errorDOIS) {
                        if (responseData) {
                            NSLog(@"Successfully posted to Facebook");
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_successful" object:nil];
                        }
                        else {
                            UIAlertView *facebookPostingError = [[UIAlertView alloc] initWithTitle:@"Oh No!"
                                                                                           message:@"There has been an error posting your Jukaela Social post to Facebook."
                                                                                          delegate:nil
                                                                                 cancelButtonTitle:@"OK"
                                                                                 otherButtonTitles:nil, nil];
                            
                            [facebookPostingError show];
                        }
                    }];
                }
                else {
                    NSLog(@"Facebook access not granted.");
                    NSLog(@"%@",[error localizedDescription]);
                }
            }];
        }
    }
}

-(void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text
{
    return;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
