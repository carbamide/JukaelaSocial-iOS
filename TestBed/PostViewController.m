//
//  PostViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/16/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "ImageConfirmationViewController.h"
#import "NSString+BackslashEscape.h"
#import "PostViewController.h"
#import "SVModalWebViewController.h"
#import "TMImgurUploader.h"
#import "UIImage+Resize.h"

@interface PostViewController ()
@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccount *facebookAccount;
@property (strong, nonatomic) NSData *tempImageData;
@property (strong, nonatomic) NSMutableArray *autocompleteUsernames;
@property (strong, nonatomic) NSMutableArray *usernameArray;
@property (strong, nonatomic) NSMutableArray *usersArray;
@property (strong, nonatomic) NSString *currentString;
@property (strong, nonatomic) NSString *currentWord;
@property (strong, nonatomic) UITableView *usernameTableView;

@property (nonatomic) BOOL imageAdded;
@property (nonatomic) BOOL isPosting;
@end

@implementation PostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self getUsers];
    
    [self setAutocompleteUsernames:[[NSMutableArray alloc] init]];
    
    UIWindow *tempWindow = [kAppDelegate window];
    
    if (tempWindow.frame.size.height > 500) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [[self photoButton] setFrame:CGRectOffset(_photoButton.frame, 0, 500)];
            [[self countDownLabel] setFrame:CGRectOffset(_countDownLabel.frame, 450, 500)];
            
            [[self theTextView] setFrame:CGRectMake(_theTextView.frame.origin.x, _theTextView.frame.origin.y, _theTextView.frame.size.width + 450, _theTextView.frame.size.height + 250)];
        }
        else {
            [[self photoButton] setFrame:CGRectOffset(_photoButton.frame, 0, 90)];
            [[self countDownLabel] setFrame:CGRectOffset(_countDownLabel.frame, 0, 90)];
            
            [[self theTextView] setFrame:CGRectMake(_theTextView.frame.origin.x, _theTextView.frame.origin.y, _theTextView.frame.size.width, _theTextView.frame.size.height + 100)];
        }
    }
    
    if (![self replyString]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
            [[self view] addSubview:GRButton(GRTypeFacebookRect, _countDownLabel.frame.origin.x - 20, _countDownLabel.frame.origin.y + 5, 30, self, @selector(toggleFacebook:), COLOR_RGB(60, 90, 154, 1), GRStyleIn)];
        }
        else {
            [[self view] addSubview:GRButton(GRTypeFacebookRect, _countDownLabel.frame.origin.x - 20, _countDownLabel.frame.origin.y + 5, 30, self, @selector(toggleFacebook:), [UIColor darkGrayColor], GRStyleIn)];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
            [[self view] addSubview:GRButton(GRTypeTwitterRect, _countDownLabel.frame.origin.x - 55, _countDownLabel.frame.origin.y + 5, 30, self, @selector(toggleTwitter:), COLOR_RGB(0, 172, 238, 1), GRStyleIn)];
        }
        else {
            [[self view] addSubview:GRButton(GRTypeTwitterRect, _countDownLabel.frame.origin.x - 55, _countDownLabel.frame.origin.y + 5, 30, self, @selector(toggleTwitter:), [UIColor darkGrayColor], GRStyleIn)];
        }
    }
    _usernameTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    
    [_usernameTableView setDelegate:self];
    [_usernameTableView setDataSource:self];
    [_usernameTableView setScrollEnabled:YES];
    [_usernameTableView setHidden:YES];
    
    [[_usernameTableView layer] setCornerRadius:8];
    [[_usernameTableView layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[_usernameTableView layer] setBorderWidth:1];
    
    [[self view] addSubview:_usernameTableView];
    
    [[self theTextView] becomeFirstResponder];
    [[self theTextView] setDelegate:self];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@-large.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [kAppDelegate userID]]]]];
    
    if (image) {
        [[self userProfileImage] setImage:image];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            UIImage *tempImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[kAppDelegate userEmail] withSize:65]]];
            
            UIImage *resizedImage = [tempImage thumbnailImage:65 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self userProfileImage] setImage:resizedImage];
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@-large", [kAppDelegate userID]]];
            });
        });
    }
    
    [[self userProfileImage] setClipsToBounds:NO];

    [[[self backgroundView] layer] setCornerRadius:8];

    [[NSNotificationCenter defaultCenter] addObserverForName:UITextViewTextDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self updateCount];
    }];
    
    if (_replyString) {
        [_theTextView setText:[_replyString stringByAppendingString:@" "]];
        
        [kAppDelegate setOnlyToJukaela:YES];
    }
}

-(void)toggleTwitter:(id)sender
{
    UIButton *tempButton = sender;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPostToTwitterPreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tempButton removeFromSuperview];
        
        [[self view] addSubview:GRButton(GRTypeTwitterRect, _countDownLabel.frame.origin.x - 55, _countDownLabel.frame.origin.y + 5, 30, self, @selector(toggleTwitter:), [UIColor darkGrayColor], GRStyleIn)];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPostToTwitterPreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tempButton removeFromSuperview];
        
        [[self view] addSubview:GRButton(GRTypeTwitterRect, _countDownLabel.frame.origin.x - 55, _countDownLabel.frame.origin.y + 5, 30, self, @selector(toggleTwitter:), COLOR_RGB(0, 172, 238, 1), GRStyleIn)];
    }
}

-(void)toggleFacebook:(id)sender
{
    UIButton *tempButton = sender;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPostToFacebookPreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tempButton removeFromSuperview];
        
        [[self view] addSubview:GRButton(GRTypeFacebookRect, _countDownLabel.frame.origin.x - 20, _countDownLabel.frame.origin.y + 5, 30, self, @selector(toggleFacebook:), [UIColor darkGrayColor], GRStyleIn)];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPostToFacebookPreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tempButton removeFromSuperview];
        
        [[self view] addSubview:GRButton(GRTypeFacebookRect, _countDownLabel.frame.origin.x - 20, _countDownLabel.frame.origin.y + 5, 30, self, @selector(toggleFacebook:), COLOR_RGB(60, 90, 154, 1), GRStyleIn)];
    }
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

-(void)setupNavbarForPosting
{
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(sendPost:)];
    
    [[self navigationItem] setRightBarButtonItem:sendButton];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPost:)];
    
    [[self navigationItem] setLeftBarButtonItem:cancelButton];
}

-(IBAction)cancelPost:(id)sender
{
    [self setIsPosting:NO];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)sendPost:(id)sender
{
    [self setIsPosting:YES];
    
    if ([kAppDelegate onlyToJukaela]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPostOnlyToJukaela object:nil];
        
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
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference] && ![[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPostOnlyToJukaela object:nil];
    }
    
    [self sendJukaelaPost:YES];
}

-(void)sendJukaelaPost:(BOOL)continuePosting
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kChangeTypeNotification object:@0];
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
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
                    [[ActivityManager sharedManager] decrementActivityCount];
                    
                    [self setupNavbarForPosting];
                }];
                
                [errorAlert show];
            }
            else {
                [self setUrlString:result[@"upload"][@"links"][@"original"]];
                
                [self jukaelaNetworkAction:stringToSendAsContent];
                
                if (continuePosting) {
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
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
                    
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
                        [self sendFacebookPost:[[self theTextView] text]];
                    }
                }
            }
        }];
    }
    else {
        [self jukaelaNetworkAction:stringToSendAsContent];
        
        if (continuePosting) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
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
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
                [self sendFacebookPost:[[self theTextView] text]];
            }
        }
    }
}

-(void)jukaelaNetworkAction:(NSString *)stringToSendAsContent
{
    stringToSendAsContent = [stringToSendAsContent stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts.json", kSocialURL]];
    
    NSString *requestString = nil;
    
    if ([self urlString]) {
        requestString = [RequestFactory postRequestWithContent:stringToSendAsContent userID:[kAppDelegate userID] imageURL:[self urlString] withReplyTo:[self inReplyTo]];
    }
    else {
        requestString = [RequestFactory postRequestWithContent:stringToSendAsContent userID:[kAppDelegate userID] imageURL:nil withReplyTo:[self inReplyTo]];
    }
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kJukaelaSuccessfulNotification object:nil];
                
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
            
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [self setupNavbarForPosting];
        }
    }];
}

- (void)sendTweet:(NSString *)stringToSend
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookOrTwitterCurrentlySending object:nil];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    if ([self tempImageData]) {
        stringToSend = [stringToSend stringByReplacingOccurrencesOfString:[self urlString] withString:@""];
    }
    
    [accountStore requestAccessToAccountsWithType:accountType options:0 completion:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            
            if ([accountsArray count] > 0) {
                ACAccount *twitterAccount = accountsArray[0];
                
                SLRequest *postRequest = nil;
                
                if ([self tempImageData]) {
                    postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"https://upload.twitter.com/1/statuses/update_with_media.json"] parameters:nil];
                    
                    [postRequest addMultipartData:[self tempImageData] withName:@"media[]" type:@"multipart/form-data" filename:@"image.jpg"];
                    [postRequest addMultipartData:[stringToSend dataUsingEncoding:NSUTF8StringEncoding] withName:@"status" type:@"multipart/form-data" filename:nil];
                    
                    [postRequest setAccount:twitterAccount];
                    
                    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        if (responseData) {
                            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                            
                            if (!jsonData[@"error"]) {
                                NSLog(@"Successfully posted to Twitter");
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:kSuccessfulTweetNotification object:nil];
                            }
                            else {
                                NSLog(@"%@", jsonData[@"error"]);
                                NSLog(@"Not posted to Twitter");
                            }
                        }
                        else {
                            [self setIsPosting:NO];
                            
                            BlockAlertView *twitterPostingError = [[BlockAlertView alloc] initWithTitle:@"Oh No!" message:@"There has been an error posting your Jukaela Social post to Twitter."];
                            
                            [twitterPostingError setCancelButtonWithTitle:@"OK" block:nil];
                            
                            [twitterPostingError show];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:kStopAnimatingActivityIndicator object:nil];
                    }];
                }
                else {
                    postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] parameters:@{@"status" : stringToSend}];
                    
                    [postRequest setAccount:twitterAccount];
                    
                    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        if (responseData) {
                            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                            
                            if (!jsonData[@"error"]) {
                                NSLog(@"Successfully posted to Twitter");
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:kSuccessfulTweetNotification object:nil];
                            }
                            else {
                                NSLog(@"%@", jsonData[@"error"]);
                                NSLog(@"Not posted to Twitter");
                            }
                        }
                        else {
                            [self setIsPosting:NO];
                            
                            BlockAlertView *twitterPostingError = [[BlockAlertView alloc] initWithTitle:@"Oh No!" message:@"There has been an error posting your Jukaela Social post to Twitter."];
                            
                            [twitterPostingError setCancelButtonWithTitle:@"OK" block:nil];
                            
                            [twitterPostingError show];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:kStopAnimatingActivityIndicator object:nil];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kJukaelaSuccessfulNotification object:nil];
            
            [kAppDelegate setOnlyToJukaela:NO];
            [kAppDelegate setOnlyToFacebook:NO];
            [kAppDelegate setOnlyToTwitter:NO];
        }];
    }
}

- (void)sendFacebookPost:(NSString *)stringToSend
{
    __block NSString *blockString = nil;
    
    NSError *error = NULL;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@[a-zA-Z0-9_]+" options:NSRegularExpressionCaseInsensitive error:&error];
    
    [regex enumerateMatchesInString:stringToSend options:0 range:NSMakeRange(0, [stringToSend length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        for (id userDict in [self usersArray]) {
            if (userDict[@"username"] != [NSNull null] && userDict[@"name"] != [NSNull null]) {
                if ([userDict[@"username"] isEqualToString:[[stringToSend substringWithRange:match.range] substringFromIndex:1]]) {
                    blockString = [stringToSend stringByReplacingOccurrencesOfString:[stringToSend substringWithRange:match.range] withString:userDict[@"name"]];
                }
            }
        }
    }];
    
    if (blockString) {
        stringToSend = blockString;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookOrTwitterCurrentlySending object:nil];
    
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
            
            NSDictionary *options = @{ACFacebookAppIdKey:@"493749340639998", ACFacebookAudienceKey: ACFacebookAudienceEveryone, ACFacebookPermissionsKey: @[@"publish_stream"]};
            
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
                                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                                
                                if (!jsonData[@"error"]) {
                                    NSLog(@"Successfully posted to Facebook");
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kSuccessfulFacebookNotification object:nil];
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
                            [[NSNotificationCenter defaultCenter] postNotificationName:kStopAnimatingActivityIndicator object:nil];
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
                                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                                
                                if (!jsonData[@"error"]) {
                                    NSLog(@"Successfully posted to Facebook");
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kSuccessfulFacebookNotification object:nil];
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
                            [[NSNotificationCenter defaultCenter] postNotificationName:kStopAnimatingActivityIndicator object:nil];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kJukaelaSuccessfulNotification object:nil];
            
            [kAppDelegate setOnlyToJukaela:NO];
            [kAppDelegate setOnlyToFacebook:NO];
            [kAppDelegate setOnlyToTwitter:NO];
        }];
    }
}

- (void)viewDidUnload
{
    [self setUserProfileImage:nil];
    [self setTheTextView:nil];
    [self setCountDownLabel:nil];
    [self setPhotoButton:nil];
    [self setBackgroundView:nil];
    [self setPostButton:nil];
    [self setCancelButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([picker sourceType] == UIImagePickerControllerSourceTypePhotoLibrary) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        
        ImageConfirmationViewController *icvc = [storyboard instantiateViewControllerWithIdentifier:@"ImageConfirmationViewController"];
        
        [icvc setPickerController:picker];
        [icvc setTheImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
        [icvc setDelegate:self];
        
        [picker pushViewController:icvc animated:YES];
    }
    else {
        [self finishImagePicking:[info objectForKey:UIImagePickerControllerOriginalImage] withImagePickerController:picker];
    }
}

-(void)finishImagePicking:(UIImage *)image withImagePickerController:(UIImagePickerController *)picker
{
    image = [image scaleAndRotateImage:image withMaxSize:640];
    
    [self setTempImageData:UIImageJPEGRepresentation(image, 10)];
    
    [[self photoButton] setImage:[image thumbnailImage:41 transparentBorder:1 cornerRadius:4 interpolationQuality:kCGInterpolationMedium] forState:UIControlStateNormal];
    
    [self setImageAdded:YES];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    return;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    CGPoint cursorPosition = [textView caretRectForPosition:textView.selectedTextRange.start].origin;
    
    [_usernameTableView setFrame:CGRectMake(cursorPosition.x, cursorPosition.y + 41, 166, 82)];
    
    [[self usernameTableView] setHidden:NO];
    
    NSString *substring = [NSString stringWithString:[textView text]];
    substring = [substring stringByReplacingCharactersInRange:range withString:text];
    
    substring = [substring stringByReplacingOccurrencesOfString:@"@" withString:@""];
    
    NSArray *tempArray = [substring componentsSeparatedByString:@" "];
    
    [self setCurrentWord:[tempArray lastObject]];
    
    [self searchAutocompleteEntriesWithSubstring:[tempArray lastObject]];
    
    
    return YES;
}

-(void)updateCount
{
    NSUInteger maxCount = 256;
    
    NSUInteger textCount = [self.theTextView.text length];
    
    [_countDownLabel setText:[NSString stringWithFormat:@"%d", maxCount-textCount]];
    
    if (textCount > maxCount) {
        [_countDownLabel setTextColor:[UIColor redColor]];
    }
    else {
        [_countDownLabel setTextColor:[UIColor darkGrayColor]];
    }
}

-(void)textViewDidChange:(UITextView *)textView
{
    if ([[textView text] length] > 0) {
        [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    }
    else {
        [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
    }
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{
    if ([[self autocompleteUsernames] count] == 0) {
        [tableView setHidden:YES];
    }
    
    return [[self autocompleteUsernames] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    static NSString *AutoCompleteRowIdentifier = @"AutoCompleteRowIdentifier";
    
    cell = [tableView dequeueReusableCellWithIdentifier:AutoCompleteRowIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AutoCompleteRowIdentifier];
        
        [cell setBackgroundView:[[CellBackground alloc] init]];
    }
    
    [[cell textLabel] setFont:[UIFont systemFontOfSize:14]];
    
    [[cell textLabel] setText:[[self autocompleteUsernames] objectAtIndex:[indexPath row]]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSRange tempRange = [[_theTextView text] rangeOfString:[self currentWord] options:NSBackwardsSearch];
    
    [_theTextView setText:[[_theTextView text] stringByReplacingCharactersInRange:tempRange withString:[[selectedCell textLabel] text]]];
    [_theTextView setText:[[_theTextView text] stringByReplacingOccurrencesOfString:@"@@" withString:@"@"]];
    
    [tableView setHidden:YES];
}

-(void)getUsers
{
    if (![self usernameArray]) {
        [self setUsernameArray:[[NSMutableArray alloc] init]];
    }
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[ActivityManager sharedManager] decrementActivityCount];
            
            NSArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            [self setUsersArray:[tempArray mutableCopy]];
            
            for (id userDict in tempArray) {
                if (userDict[kUsername] && userDict[kUsername] != [NSNull null]) {
                    [[self usernameArray] addObject:userDict[kUsername]];
                }
            }
        }
        else {
            NSLog(@"Error retrieving users");
        }
    }];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    if (![_usernameTableView isHidden]) {
        id view = [touch view];
        
        if (![view isEqual:_usernameTableView]) {
            [_usernameTableView setHidden:YES];
        }
    }
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    [_autocompleteUsernames removeAllObjects];
    
    substring = [substring stringByReplacingOccurrencesOfString:@"@" withString:@""];
    
    for (NSString *curString in [self usernameArray]) {
        NSRange substringRange = [curString rangeOfString:substring options:NSCaseInsensitiveSearch];
        if (substringRange.location == 0) {
            [_autocompleteUsernames addObject:[NSString stringWithFormat:@"@%@", curString]];
        }
    }
    
    [[self usernameTableView] reloadData];
}

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];
    
    [super viewDidAppear:animated];
}

@end
