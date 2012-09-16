//
//  PostViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/16/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Accounts/Accounts.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_1
#import <Social/Social.h>
#endif
#import <Twitter/Twitter.h>
#import "AppDelegate.h"
#import "PostViewController.h"
#import "NSString+BackslashEscape.h"
#import "SVModalWebViewController.h"
#import "TMImgurUploader.h"
#import "UIAlertView+Blocks.h"
#import "UIImage+Resize.h"

@interface PostViewController ()
@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccount *facebookAccount;

@property (strong, nonatomic) NSData *tempImageData;

@end

@implementation PostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavbarForPosting];
}

-(void)photoSheet:(id)sender
{
    BlockActionSheet *photoActionSheet = [[BlockActionSheet alloc] initWithTitle:@"Photo Source"];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [photoActionSheet addButtonWithTitle:@"Take Photo" block:^{
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            
            [imagePicker setDelegate:self];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [imagePicker setAllowsEditing:NO];
            
            [self presentViewController:imagePicker animated:YES completion:nil];
        }];
    }
    
    [photoActionSheet addButtonWithTitle:@"Choose Existing" block:^{
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        [imagePicker setDelegate:self];
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [imagePicker setAllowsEditing:NO];
        
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
    
    [photoActionSheet setCancelButtonWithTitle:@"Cancel" block:nil];
    
    [photoActionSheet showInView:[self view]];
}

-(void)viewDidAppear:(BOOL)animated
{
    NSString *tempString = [_theTextView text];
    
    if (_replyString) {
        _theTextView = [[YIPopupTextView alloc] initWithText:[self replyString] maxCount:140];
    }
    else if (_repostString) {
        _theTextView = [[YIPopupTextView alloc] initWithText:[self repostString] maxCount:140];
    }
    else if (_urlString) {
        if ([tempString length] > 0) {
            _theTextView = [[YIPopupTextView alloc] initWithText:[[tempString stringByAppendingString:@" "] stringByAppendingString:[self urlString]] maxCount:140];
        }
        else {
            _theTextView = [[YIPopupTextView alloc] initWithText:[self urlString] maxCount:140];
        }
    }
    else {
        _theTextView = [[YIPopupTextView alloc] initWithPlaceHolder:@"Make a post, you guys!" maxCount:140];
    }
    
    if ([[_theTextView text] length] > 0) {
        [_theTextView setEditable:YES];
        
        [_theTextView setText:[[_theTextView text] stringByAppendingString:@" "]];
    }
    [_theTextView setDelegate:self];
    [_theTextView setShowCloseButton:NO];
    
    [_theTextView setFrame:CGRectMake(_theTextView.frame.origin.x, _theTextView.frame.origin.y, _theTextView.frame.size.width, _theTextView.frame.size.height - 20)];
        
    [_theTextView showInView:[self view]];
}

-(void)setupNavbarForPosting
{
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendPost:)];
    
    UIBarButtonItem *photoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(photoSheet:)];
    
    [[self navigationItem] setRightBarButtonItems:@[sendButton, photoButton]];
    
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
        BlockAlertView *confirmAlert = [[BlockAlertView alloc] initWithTitle:@"Confirm" message:@"Confirm sending to other services?"];
        
        [confirmAlert addButtonWithTitle:@"Do it!" block:^{
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
                [self sendTweet:[[self theTextView] text]];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
                [self sendFacebookPost:[[self theTextView] text]];
            }
            
            [self sendJukaelaPost];
        }];
        
        [confirmAlert addButtonWithTitle:@"Just to Jukaela!" block:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"just_to_jukaela" object:nil];
            
            [self sendJukaelaPost];
        }];
        
        [confirmAlert setCancelButtonWithTitle:@"Cancel" block:nil];
        
        [confirmAlert show];
    }
    else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
            [self sendTweet:[[self theTextView] text]];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
            [self sendFacebookPost:[[self theTextView] text]];
        }
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"just_to_jukaela" object:nil];
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
        
    NSData *tempData = [[[[self theTextView] text] stringWithSlashEscapes] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *stringToSendAsContent = [[NSString alloc] initWithData:tempData encoding:NSASCIIStringEncoding];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", stringToSendAsContent, [kAppDelegate userID]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"jukaela_successful" object:nil];
            }];
        }
        else {
            BlockAlertView *jukaelaSocialPostingError = [[BlockAlertView alloc] initWithTitle:@"Oh No!" message:@"There has been an error posting to Jukaela Social"];
            
            [jukaelaSocialPostingError setCancelButtonWithTitle:@"OK" block:nil];
            
            [jukaelaSocialPostingError show];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self setupNavbarForPosting];
        }
    }];
}

- (void)sendTweet:(NSString *)stringToSend
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_or_twitter_sending" object:nil];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    if ([self tempImageData]) {
        stringToSend = [stringToSend stringByReplacingOccurrencesOfString:[self urlString] withString:@""];
    }
    
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            
            if ([accountsArray count] > 0) {
                ACAccount *twitterAccount = accountsArray[0];
                
                TWRequest *postRequest = nil;
                
                if (![[twitterAccount credential] oauthToken]) {
                    [_accountStore renewCredentialsForAccount:twitterAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                        if (error) {
                            NSLog(@"error:%@", [error localizedDescription]);
                        }
                    }];
                }
                
                if ([self tempImageData]) {
                    postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://upload.twitter.com/1/statuses/update_with_media.json"] parameters:nil requestMethod:TWRequestMethodPOST];
                    
                    [postRequest addMultiPartData:[self tempImageData] withName:@"media[]" type:@"multipart/form-data"];
                    
                    [postRequest addMultiPartData:[stringToSend dataUsingEncoding:NSUTF8StringEncoding] withName:@"status" type:@"multipart/form-data"];
                    
                    [postRequest setAccount:twitterAccount];
                    
                    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        if (responseData) {
                            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                            
                            NSLog(@"The Twitter response was \n%@", jsonData);
                            
                            if (!jsonData[@"error"]) {
                                NSLog(@"Successfully posted to Twitter");
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"tweet_successful" object:nil];
                            }
                            else {
                                NSLog(@"Not posted to Twitter");
                            }
                        }
                        else {
                            BlockAlertView *twitterPostingError = [[BlockAlertView alloc] initWithTitle:@"Oh No!" message:@"There has been an error posting your Jukaela Social post to Twitter."];
                            
                            [twitterPostingError setCancelButtonWithTitle:@"OK" block:nil];
                            
                            [twitterPostingError show];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"stop_animating" object:nil];
                    }];
                }
                else {
                    postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] parameters:@{@"status": stringToSend} requestMethod:TWRequestMethodPOST];
                    
                    [postRequest setAccount:twitterAccount];
                    
                    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        if (responseData) {
                            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                            
                            NSLog(@"The Twitter response was \n%@", jsonData);
                            
                            if (!jsonData[@"error"]) {
                                NSLog(@"Successfully posted to Twitter");
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"tweet_successful" object:nil];
                            }
                            else {
                                NSLog(@"Not posted to Twitter");
                            }
                        }
                        else {
                            BlockAlertView *twitterPostingError = [[BlockAlertView alloc] initWithTitle:@"Oh No!" message:@"There has been an error posting your Jukaela Social post to Twitter."];
                            
                            [twitterPostingError setCancelButtonWithTitle:@"OK" block:nil];
                            
                            [twitterPostingError show];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"stop_animating" object:nil];
                    }];
                }
                

            }
        }
        else {
            NSLog(@"Twitter access not granted.");
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

- (void)sendFacebookPost:(NSString *)stringToSend
{    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_or_twitter_sending" object:nil];

    if ([self tempImageData]) {
        stringToSend = [stringToSend stringByReplacingOccurrencesOfString:[self urlString] withString:@""];
    }
    
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
                    
                    if (![[[self facebookAccount] credential] oauthToken]) {
                        [_accountStore renewCredentialsForAccount:[self facebookAccount] completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                            if (error) {
                                NSLog(@"error:%@", [error localizedDescription]);
                            }
                        }];
                    }
                    
                    NSLog(@"Token: %@", [[[self facebookAccount] credential] oauthToken]);
                    
                    if ([self tempImageData]) {
                        NSDictionary *parameters = @{@"access_token":[[[self facebookAccount] credential] oauthToken], @"message":stringToSend};
                        NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/photos"];
                        
                        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
                        
                        [request addMultipartData:[self tempImageData] withName:stringToSend type:@"multipart/form-data" filename:@"image.jpg"];
                        
                        [request setAccount:[self facebookAccount]];
                        
                        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *errorDOIS) {
                            if (responseData) {
                                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                                
                                NSLog(@"The Facebook response was \n%@", jsonData);
                                
                                if (!jsonData[@"error"]) {
                                    NSLog(@"Successfully posted to Facebook");
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_successful" object:nil];
                                }
                                else {
                                    NSLog(@"Not posted to Facebook");
                                }
                            }
                            else {
                                BlockAlertView *facebookPostingError = [[BlockAlertView alloc] initWithTitle:@"Oh No!" message:@"There has been an error posting your Jukaela Social post to Facebook."];
                                
                                [facebookPostingError setCancelButtonWithTitle:@"OK" block:nil];
                                
                                [facebookPostingError show];
                            }
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"stop_animating" object:nil];
                        }];
                    }
                    else {
                        NSDictionary *parameters = @{@"access_token":[[[self facebookAccount] credential] oauthToken], @"message":stringToSend};
                        NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
                        
                        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
                        
                        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *errorDOIS) {
                            if (responseData) {
                                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                                
                                NSLog(@"The Facebook response was \n%@", jsonData);
                                
                                if (!jsonData[@"error"]) {
                                    NSLog(@"Successfully posted to Facebook");
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_successful" object:nil];
                                }
                                else {
                                    NSLog(@"Not posted to Facebook");
                                }
                            }
                            else {
                                BlockAlertView *facebookPostingError = [[BlockAlertView alloc] initWithTitle:@"Oh No!" message:@"There has been an error posting your Jukaela Social post to Facebook."];
                                
                                [facebookPostingError setCancelButtonWithTitle:@"OK" block:nil];
                                
                                [facebookPostingError show];
                            }
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"stop_animating" object:nil];
                        }];
                    }
                }
                else {
                    NSLog(@"Facebook access not granted.");
                    NSLog(@"%@", [error localizedDescription]);
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

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    originalImage = [originalImage scaleAndRotateImage:originalImage withMaxSize:640];
    
    [self setTempImageData:UIImageJPEGRepresentation(originalImage, 10)];
    
    [[TMImgurUploader sharedInstance] uploadImage:originalImage finishedBlock:^(NSDictionary *result, NSError *error){
        NSLog(@"%@", result[@"upload"][@"links"][@"imgur_page"]);
        
        if (error) {
            NSLog(@"%@", [error description]);
            
            BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription]];
            
            [errorAlert setCancelButtonWithTitle:@"OK" block:nil];
            
            [errorAlert show];
        }
        else {
            [self setUrlString:result[@"upload"][@"links"][@"imgur_page"]];
            
            [picker dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

-(void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    return;
}

- (void)handleURL:(NSURL*)url
{
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[url absoluteString]];
    
    [webViewController setBarsTintColor:[UIColor darkGrayColor]];
    
    [self presentModalViewController:webViewController animated:YES];
}
@end
