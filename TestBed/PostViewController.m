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

@property (strong, nonatomic) NSString *currentString;

@property (nonatomic) BOOL isPosting;
@property (nonatomic) BOOL imageAdded;

@end

@implementation PostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavbarForPosting];
    
    [[self theTextView] becomeFirstResponder];
    [[self theTextView] setDelegate:self];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [kAppDelegate userEmail]]]]];
    
    [[self userProfileImage] setImage:image];
    
    [[[self userProfileImage] layer] setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [[[self userProfileImage] layer] setShadowRadius:8];
    [[[self userProfileImage] layer] setShadowOpacity:0.8];
    [[[self userProfileImage] layer] setShadowOffset:CGSizeMake(0, 2)];
    
    [[[self backgroundView] layer] setCornerRadius:8];
    
    [[[self backgroundView] layer] setShadowColor:[[UIColor blackColor] CGColor]];
    [[[self backgroundView] layer] setShadowRadius:8];
    [[[self backgroundView] layer] setShadowOpacity:1.0];
    [[[self backgroundView] layer] setShadowOffset:CGSizeMake(0, 5)];
    
    if ([self imageFromExternalSource]) {
        [self setTempImageData:UIImageJPEGRepresentation([self imageFromExternalSource], 1.0)];
        
        UIBarButtonItem *tempButton = [[self navigationItem] rightBarButtonItems][1];
        
        [tempButton setTintColor:[UIColor blueColor]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextViewTextDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self updateCount];
    }];
}

-(IBAction)takePhoto:(id)sender
{
    if ([self imageAdded]) {
        BlockActionSheet *removePhotoActionSheet = [[BlockActionSheet alloc] initWithTitle:@"Remove photo?"];
        
        [removePhotoActionSheet setDestructiveButtonWithTitle:@"Remove Photo" block:^{
            [self setTempImageData:nil];
            
            [[self photoButton] setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
            
            [self setImageAdded:NO];
        }];
        
        [removePhotoActionSheet setCancelButtonWithTitle:@"Cancel" block:nil];
        
        [removePhotoActionSheet showInView:[self view]];
    }
    else {
        if ([self tempImageData]) {
            BlockActionSheet *removePhoto = [[BlockActionSheet alloc] initWithTitle:@"Remove photo?"];
            
            [removePhoto setDestructiveButtonWithTitle:@"Remove Photo" block:^{
                [self setUrlString:nil];
                [self setTempImageData:nil];
            }];
            
            [removePhoto setCancelButtonWithTitle:@"Cancel" block:nil];
            
            [removePhoto showInView:[self view]];
        }
        else {
            BlockActionSheet *photoActionSheet = [[BlockActionSheet alloc] initWithTitle:@"Photo Source"];
            
            [self setCurrentString:[[self theTextView] text]];
            
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
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    if ([[_theTextView text] length] > 0) {
        [[[self navigationItem] rightBarButtonItems][0] setEnabled:YES];
    }
    else {
        [[[self navigationItem] rightBarButtonItems][0] setEnabled:NO];
    }
}

-(void)setupNavbarForPosting
{
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(sendPost:)];
    
    [[self navigationItem] setRightBarButtonItem:sendButton];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPost:)];
    
    [[self navigationItem] setLeftBarButtonItem:cancelButton];
}

-(void)cancelPost:(id)sender
{
    [self setIsPosting:NO];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)sendPost:(id)sender
{
    [self setIsPosting:YES];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"confirm_post"] == YES && ![kAppDelegate onlyToTwitter] && ![kAppDelegate onlyToFacebook] && ![kAppDelegate onlyToJukaela]) {
        BlockAlertView *confirmAlert = [[BlockAlertView alloc] initWithTitle:@"Confirm" message:@"Confirm sending to other services?"];
        
        [confirmAlert addButtonWithTitle:@"Do it!" block:^{
            [self sendJukaelaPost:YES];
        }];
        
        [confirmAlert addButtonWithTitle:@"Just to Jukaela!" block:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"just_to_jukaela" object:nil];
            
            [self sendJukaelaPost:NO];
        }];
        
        [confirmAlert setCancelButtonWithTitle:@"Cancel" block:nil];
        
        [confirmAlert show];
    }
    else {
        if ([kAppDelegate onlyToJukaela]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"just_to_jukaela" object:nil];
            
            [self sendJukaelaPost:NO];
            
            return;
        }
        
        if ([kAppDelegate onlyToFacebook]) {
            [self sendFacebookPost:[[self theTextView] text]];
            
            return;
        }
        
        if ([kAppDelegate onlyToTwitter]) {
            if ([[[self theTextView] text] length] > 140) {
                NSArray *tempArray = [Helpers splitString:[[self theTextView] text] maxCharacters:140];
                
                for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                    [self sendTweet:tempString];
                }
            }
            else {
                [self sendTweet:[[self theTextView] text]];
            }
            return;
        }
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"just_to_jukaela" object:nil];
        }
        
        [self sendJukaelaPost:YES];
    }
}

-(void)sendJukaelaPost:(BOOL)continuePosting
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
    
    NSData *tempData = [[[[self theTextView] text] stringWithSlashEscapes] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *stringToSendAsContent = [[NSString alloc] initWithData:tempData encoding:NSASCIIStringEncoding];
    
    if ([self tempImageData]) {
        [[TMImgurUploader sharedInstance] uploadImage:[UIImage imageWithData:[self tempImageData]] finishedBlock:^(NSDictionary *result, NSError *error){
            if (error) {
                [self setIsPosting:NO];
                
                BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription]];
                
                [errorAlert setCancelButtonWithTitle:@"OK" block:^{
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    
                    [self setupNavbarForPosting];
                }];
                
                [errorAlert show];
            }
            else {
                [self setUrlString:result[@"upload"][@"links"][@"original"]];
                
                [self jukaelaNetworkAction:stringToSendAsContent];
                
                if (continuePosting) {
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
                        if ([[[self theTextView] text] length] > 140) {
                            NSArray *tempArray = [Helpers splitString:[[self theTextView] text] maxCharacters:140];
                            
                            for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                                [self sendTweet:tempString];
                            }
                        }
                        else {
                            [self sendTweet:[[self theTextView] text]];
                        }
                    }
                    
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
                        [self sendFacebookPost:[[self theTextView] text]];
                    }
                }
            }
        }];
    }
    else {
        [self jukaelaNetworkAction:stringToSendAsContent];
        
        if (continuePosting) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
                if ([[[self theTextView] text] length] > 140) {
                    NSArray *tempArray = [Helpers splitString:[[self theTextView] text] maxCharacters:140];
                    
                    for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                        [self sendTweet:tempString];
                    }
                }
                else {
                    [self sendTweet:[[self theTextView] text]];
                }
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
                [self sendFacebookPost:[[self theTextView] text]];
            }
        }
    }
}

-(void)jukaelaNetworkAction:(NSString *)stringToSendAsContent
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts.json", kSocialURL]];
    
    NSString *requestString = nil;
    
    if ([self urlString]) {
        requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@, \"image_url\": \"%@\"}", stringToSendAsContent, [kAppDelegate userID], [self urlString]];
    }
    else {
        requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", stringToSendAsContent, [kAppDelegate userID]];
    }
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"jukaela_successful" object:nil];
                
                [kAppDelegate setOnlyToJukaela:NO];
                [kAppDelegate setOnlyToFacebook:NO];
                [kAppDelegate setOnlyToTwitter:NO];
            }];
        }
        else {
            [self setIsPosting:NO];
            
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
                
                if ([self tempImageData]) {
                    postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://upload.twitter.com/1/statuses/update_with_media.json"] parameters:nil requestMethod:TWRequestMethodPOST];
                    
                    [postRequest addMultiPartData:[self tempImageData] withName:@"media[]" type:@"multipart/form-data"];
                    
                    [postRequest addMultiPartData:[stringToSend dataUsingEncoding:NSUTF8StringEncoding] withName:@"status" type:@"multipart/form-data"];
                    
                    [postRequest setAccount:twitterAccount];
                    
                    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        if (responseData) {
                            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                            
                            if (!jsonData[@"error"]) {
                                NSLog(@"Successfully posted to Twitter");
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"tweet_successful" object:nil];
                            }
                            else {
                                NSLog(@"Not posted to Twitter");
                            }
                        }
                        else {
                            [self setIsPosting:NO];
                            
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
                            
                            if (!jsonData[@"error"]) {
                                NSLog(@"Successfully posted to Twitter");
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"tweet_successful" object:nil];
                            }
                            else {
                                NSLog(@"Not posted to Twitter");
                            }
                        }
                        else {
                            [self setIsPosting:NO];
                            
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
    
    if ([kAppDelegate onlyToTwitter]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"jukaela_successful" object:nil];
            
            [kAppDelegate setOnlyToJukaela:NO];
            [kAppDelegate setOnlyToFacebook:NO];
            [kAppDelegate setOnlyToTwitter:NO];
        }];
    }
}

- (void)sendFacebookPost:(NSString *)stringToSend
{
    NSLinguisticTaggerOptions options = NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerOmitPunctuation | NSLinguisticTaggerJoinNames;
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes: [NSLinguisticTagger availableTagSchemesForLanguage:@"en"] options:options];
    tagger.string = [[self theTextView] text];
    [tagger enumerateTagsInRange:NSMakeRange(0, [[[self theTextView] text] length]) scheme:NSLinguisticTagSchemeNameTypeOrLexicalClass options:options usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
        NSString *token = [[[self theTextView] text] substringWithRange:tokenRange];
        NSLog(@"%@: %@", token, tag);
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_or_twitter_sending" object:nil];
    
    if ([self tempImageData]) {
        stringToSend = [stringToSend stringByReplacingOccurrencesOfString:[self urlString] withString:@""];
    }
    
    NSArray *urlArray = [Helpers arrayOfURLsFromString:stringToSend error:nil];
    
    BOOL urls = NO;
    
    if ([urlArray count] > 0) {
        urls = YES;
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        if (NSStringFromClass([SLRequest class])) {
            if (_accountStore == nil) {
                _accountStore = [[ACAccountStore alloc] init];
            }
            
            ACAccountType *accountTypeFacebook = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
            
            NSDictionary *options = @{ACFacebookAppIdKey:@"493749340639998", ACFacebookAudienceKey: ACFacebookAudienceEveryone, ACFacebookPermissionsKey: @[@"publish_stream", @"publish_actions", @"read_friendlists"]};
            
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
                    
                    if ([self tempImageData]) {
                        NSDictionary *parameters = @{@"access_token":[[[self facebookAccount] credential] oauthToken], @"message":stringToSend};
                        NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/photos"];
                        
                        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
                        
                        [request addMultipartData:[self tempImageData] withName:stringToSend type:@"multipart/form-data" filename:@"image.jpg"];
                        
                        [request setAccount:[self facebookAccount]];
                        
                        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *errorDOIS) {
                            if (responseData) {
                                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                                
                                if (!jsonData[@"error"]) {
                                    NSLog(@"Successfully posted to Facebook");
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_successful" object:nil];
                                }
                                else {
                                    NSLog(@"Not posted to Facebook");
                                }
                            }
                            else {
                                [self setIsPosting:NO];
                                
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
                        
                        if (urls) {
                            feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/links"];
                            
                            parameters = @{@"access_token" : [[[self facebookAccount] credential] oauthToken], @"message" : stringToSend, @"link" : urlArray[0]};
                        }
                        
                        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
                        
                        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *errorDOIS) {
                            if (responseData) {
                                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                                
                                if (!jsonData[@"error"]) {
                                    NSLog(@"Successfully posted to Facebook");
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_successful" object:nil];
                                }
                                else {
                                    NSLog(@"Not posted to Facebook");
                                }
                            }
                            else {
                                [self setIsPosting:NO];
                                
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
    
    if ([kAppDelegate onlyToFacebook]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"jukaela_successful" object:nil];
            
            [kAppDelegate setOnlyToJukaela:NO];
            [kAppDelegate setOnlyToFacebook:NO];
            [kAppDelegate setOnlyToTwitter:NO];
        }];
    }
}

-(void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text
{
    return;
}

- (void)viewDidUnload
{
    [self setUserProfileImage:nil];
    [self setTheTextView:nil];
    [self setCountDownLabel:nil];
    [self setPhotoButton:nil];
    [self setBackgroundView:nil];
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
    
    [[self photoButton] setImage:[originalImage thumbnailImage:41 transparentBorder:1 cornerRadius:4 interpolationQuality:kCGInterpolationMedium] forState:UIControlStateNormal];
    
    [self setImageAdded:YES];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
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


-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([self isPosting]) {
        return NO;
    }
    else {
        return YES;
    }
}

-(void)updateCount
{
    NSUInteger maxCount = 256;
    
    NSUInteger textCount = [self.theTextView.text length];
    
    _countDownLabel.text = [NSString stringWithFormat:@"%d", maxCount-textCount];
    
    NSLog(@"%d", maxCount - textCount);
    
    if (textCount > maxCount) {
        _countDownLabel.textColor = [UIColor redColor];
    } else {
        _countDownLabel.textColor = [UIColor darkGrayColor];
    }
}

-(void)textViewDidChange:(UITextView *)textView
{
    if ([[textView text] length] > 0) {
        [[[self navigationItem] rightBarButtonItems][0] setEnabled:YES];
    }
    else {
        [[[self navigationItem] rightBarButtonItems][0] setEnabled:NO];
    }
}

@end
