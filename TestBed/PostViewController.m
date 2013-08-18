//
//  PostViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/16/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "GravatarHelper.h"
#import "GRButtons.h"
#import "ImageConfirmationViewController.h"
#import "PostViewController.h"
#import "TMImgurUploader.h"
#import "NSString+BackslashEscape.h"

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
        [[self photoButton] setFrame:CGRectOffset(_photoButton.frame, 0, 90)];
        [[self countDownLabel] setFrame:CGRectOffset(_countDownLabel.frame, 0, 90)];
        
        [[self theTextView] setFrame:CGRectMake(_theTextView.frame.origin.x, _theTextView.frame.origin.y, _theTextView.frame.size.width, _theTextView.frame.size.height + 100)];
    }
    
    if (![self replyString]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
            UIButton *facebookButton = GRButton(GRTypeFacebookRect, _countDownLabel.frame.origin.x - 20, _countDownLabel.frame.origin.y + 75, 30, self, @selector(toggleFacebook:), COLOR_RGB(60, 90, 154, 1), GRStyleIn);
            
            [[self view] addSubview:facebookButton];
        }
        else {
            UIButton *facebookButton = GRButton(GRTypeFacebookRect, _countDownLabel.frame.origin.x - 20, _countDownLabel.frame.origin.y + 75, 30, self, @selector(toggleFacebook:), [UIColor darkGrayColor], GRStyleIn);
            
            
            [[self view] addSubview:facebookButton];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
            UIButton *twitterButton = GRButton(GRTypeTwitterRect, _countDownLabel.frame.origin.x - 55, _countDownLabel.frame.origin.y + 75, 30, self, @selector(toggleTwitter:), COLOR_RGB(0, 172, 238, 1), GRStyleIn);
            
            [[self view] addSubview:twitterButton];
        }
        else {
            UIButton *twitterButton = GRButton(GRTypeTwitterRect, _countDownLabel.frame.origin.x - 55, _countDownLabel.frame.origin.y + 75, 30, self, @selector(toggleTwitter:), [UIColor darkGrayColor], GRStyleIn);
            
            [[self view] addSubview:twitterButton];
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
    
    [[self backgroundView] setBackgroundColor:[UIColor clearColor]];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextViewTextDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self updateCount];
    }];
}

-(void)toggleTwitter:(id)sender
{
    UIButton *tempButton = sender;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPostToTwitterPreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tempButton removeFromSuperview];
        
        UIButton *twitterButton = GRButton(GRTypeTwitterRect, _countDownLabel.frame.origin.x - 55, _countDownLabel.frame.origin.y + 75, 30, self, @selector(toggleTwitter:), [UIColor darkGrayColor], GRStyleIn);
        
        [[self view] addSubview:twitterButton];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPostToTwitterPreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tempButton removeFromSuperview];
        
        UIButton *twitterButton = GRButton(GRTypeTwitterRect, _countDownLabel.frame.origin.x - 55, _countDownLabel.frame.origin.y + 75, 30, self, @selector(toggleTwitter:), COLOR_RGB(0, 172, 238, 1), GRStyleIn);
        
        [[self view] addSubview:twitterButton];
    }
}

-(void)toggleFacebook:(id)sender
{
    UIButton *tempButton = sender;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPostToFacebookPreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tempButton removeFromSuperview];
        
        UIButton *facebookButton = GRButton(GRTypeFacebookRect, _countDownLabel.frame.origin.x - 20, _countDownLabel.frame.origin.y + 75, 30, self, @selector(toggleFacebook:), [UIColor darkGrayColor], GRStyleIn);
        
        [[self view] addSubview:facebookButton];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPostToFacebookPreference];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tempButton removeFromSuperview];
        
        UIButton *facebookButton = GRButton(GRTypeFacebookRect, _countDownLabel.frame.origin.x - 20, _countDownLabel.frame.origin.y + 75, 30, self, @selector(toggleFacebook:), COLOR_RGB(60, 90, 154, 1), GRStyleIn);
        
        
        [[self view] addSubview:facebookButton];
    }
}

-(IBAction)takePhoto:(id)sender
{
    if ([self imageAdded]) {
        RIButtonItem *removePhotoButton = [RIButtonItem itemWithLabel:@"Remove Photo" action:^{
            [self setTempImageData:nil];
            
            [[self photoButton] setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
            
            [self setImageAdded:NO];
        }];
        
        UIActionSheet *removePhotoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Remove Photo?" cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] destructiveButtonItem:removePhotoButton otherButtonItems:nil, nil];
        
        [removePhotoActionSheet showInView:[self backgroundView]];
    }
    else {
        if ([self tempImageData]) {
            RIButtonItem *removePhotoButton = [RIButtonItem itemWithLabel:@"Remove Photo" action:^{
                [self setUrlString:nil];
                [self setTempImageData:nil];
            }];
            
            UIActionSheet *removePhotoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Remove Photo?" cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] destructiveButtonItem:removePhotoButton otherButtonItems:nil, nil];
            
            [removePhotoActionSheet showInView:[self backgroundView]];
        }
        else {
            RIButtonItem *takePhoto = [RIButtonItem itemWithLabel:@"Take Photo" action:^{
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                
                [imagePicker setDelegate:self];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
                [imagePicker setAllowsEditing:NO];
                
                [self presentViewController:imagePicker animated:YES completion:nil];
            }];
            
            RIButtonItem *chooseExisting = [RIButtonItem itemWithLabel:@"Choose Existing" action:^{
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                
                [imagePicker setDelegate:self];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [imagePicker setAllowsEditing:NO];
                
                [self presentViewController:imagePicker animated:YES completion:nil];
            }];
            
            UIActionSheet *photoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Photo Source" cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] destructiveButtonItem:nil otherButtonItems:takePhoto, chooseExisting, nil];
            
            [photoActionSheet showInView:[self backgroundView]];
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
    
    [activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    
    [activityView startAnimating];
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
    [[self navigationItem] setRightBarButtonItem:loadingView];
    
    NSData *tempData = [[[[self theTextView] text] stringWithSlashEscapes] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *stringToSendAsContent = [[NSString alloc] initWithData:tempData encoding:NSASCIIStringEncoding];
    
    if ([self tempImageData]) {
        [[TMImgurUploader sharedInstance] uploadImage:[UIImage imageWithData:[self tempImageData]] finishedBlock:^(NSDictionary *result, NSError *error){
            if (error) {
                [self setIsPosting:NO];
                
                RIButtonItem *errorItem = [RIButtonItem itemWithLabel:@"OK" action:^{
                    [[ActivityManager sharedManager] decrementActivityCount];
                    
                    [self setupNavbarForPosting];
                }];
                
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] cancelButtonItem:errorItem otherButtonItems:nil, nil];
                
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
            
            UIAlertView *jukaelaSocialPostingError = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"There has been an error posting to Jukaela Social!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            
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
                            
                            UIAlertView *jukaelaSocialPostingError = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"There has been an error posting your Jukaela Social post to Twitter." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            
                            [jukaelaSocialPostingError show];
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
                            
                            UIAlertView *jukaelaSocialPostingError = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"There has been an error posting your Jukaela Social post to Twitter." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            
                            [jukaelaSocialPostingError show];
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
                            
                            UIAlertView *jukaelaSocialPostingError = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"There has been an error posting your Jukaela Social post to Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            
                            [jukaelaSocialPostingError show];
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
                            
                            UIAlertView *jukaelaSocialPostingError = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"There has been an error posting your Jukaela Social post to Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            
                            [jukaelaSocialPostingError show];
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
    static int TableWidth = 166;
    static int TableHeight = 82;
    static int DeviceWidth = 320;
    static int Spacing = 5;
    
    CGPoint cursorPosition = [textView caretRectForPosition:textView.selectedTextRange.start].origin;
    CGPoint translatedPosition = [[self view] convertPoint:cursorPosition fromView:[self theTextView]];
        
    CGPoint finalPoint = CGPointMake(translatedPosition.x, translatedPosition.y + [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] pointSize] + Spacing);
    
    if ((finalPoint.x + TableWidth) > DeviceWidth) {
        finalPoint = CGPointMake(finalPoint.x - ((finalPoint.x + TableWidth) - DeviceWidth), finalPoint.y);
    }
    
    [_usernameTableView setFrame:CGRectMake(finalPoint.x, finalPoint.y, TableWidth, TableHeight)];
    
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
    static NSUInteger maxCount = 256;
    
    NSUInteger textCount = [[[self theTextView] text] length];
    
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
    
    [[cell textLabel] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
    
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_replyString) {
        [_theTextView setText:[_replyString stringByAppendingString:@" "]];
        
        [kAppDelegate setOnlyToJukaela:YES];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [kAppDelegate setCurrentViewController:self];
}

@end
