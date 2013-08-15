//
//  FeedViewController.m
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//
#import <Accounts/Accounts.h>
#import <objc/runtime.h>
#import <Social/Social.h>
#import "AHMarkedHyperlink.h"
#import "FeedViewController.h"
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "LoginViewController.h"
#import "NormalCellView.h"
#import "NormalWithImageCellView.h"
#import "PhotoViewerViewController.h"
#import "PostViewController.h"
#import "SFHFKeychainUtils.h"
#import "ShareManager.h"
#import "ShowUserViewController.h"
#import "SVModalWebViewController.h"
#import "ThreadedPostsViewController.h"
#import "UsersWhoLikedViewController.h"
#import "WBErrorNoticeView.h"
#import "WBStickyNoticeView.h"
#import "WBSuccessNoticeView.h"
#import "ObjectMapper.h"

@interface FeedViewController ()
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (strong, nonatomic) NSMutableArray *tempArray;
@property (strong, nonatomic) NSString *documentsFolder;
@property (strong, nonatomic) NSString *stringToPost;
@property (strong, nonatomic) NSTimer *refreshTimer;
@property (strong, nonatomic) UIImage *tempImage;

@property (strong, nonatomic) MBProgressHUD *progressHUD;

@property (nonatomic) enum ChangeType currentChangeType;

@property (nonatomic) BOOL fbSuccess;
@property (nonatomic) BOOL jukaelaSuccess;
@property (nonatomic) BOOL justToJukaela;
@property (nonatomic) BOOL twitterSuccess;

-(void)refreshTableInformation:(NSIndexPath *)indexPath from:(NSInteger)from to:(NSInteger)to removeSplash:(BOOL)removeSplash;

@end

@implementation FeedViewController

-(id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doubleTap:) name:kDoubleTapNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToSelectedUser:) name:kSendToUserNotification object:nil];
    
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDoubleTapNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSendToUserNotification object:nil];
    
    [super viewDidDisappear:animated];
}

-(void)viewDidLoad
{    
    [self setExternalImageCache:[[NSCache alloc] init]];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    [refreshControl setTintColor:[UIColor blackColor]];
    
    [refreshControl addTarget:self action:@selector(refreshControlRefresh:) forControlEvents:UIControlEventValueChanged];
    
    [self setRefreshControl:refreshControl];
    
    [self setDocumentsFolder:[Helpers documentsPath]];
    
    [self setupNotifications];
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composePost:)];
    
    [[self navigationItem] setRightBarButtonItem:composeButton];
    [[self navigationItem] setHidesBackButton:YES];
    
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    
    [gesture setDelegate:self];
    
    [[[[self navigationItem] rightBarButtonItem] valueForKey:@"view"] addGestureRecognizer:gesture];
    
    [self setCurrentChangeType:-1];
    
    if ([self loadedDirectly] && [[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference] == YES) {
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSError *error = nil;
        
        NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:kUsername];
        NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:kJukaelaSocialServiceName error:&error];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/sessions.json", kSocialURL]];
        
        NSString *requestString = [RequestFactory loginRequestWithEmail:username password:password apns:[[NSUserDefaults standardUserDefaults] valueForKey:kDeviceTokenPreference]];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                NSDictionary *loginDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                if (loginDict) {
                    for (UITabBarItem *item in [[[self tabBarController] tabBar] items]) {
                        [item setEnabled:YES];
                    }
                    
                    [kAppDelegate setUserID:[NSString stringWithFormat:@"%@", loginDict[kID]]];
                    [kAppDelegate setUserEmail:[NSString stringWithFormat:@"%@", loginDict[kEmail]]];
                    [kAppDelegate setUserUsername:[NSString stringWithFormat:@"%@", loginDict[kUsername]]];
                    
                    [[NSUserDefaults standardUserDefaults] setValue:[kAppDelegate userID] forKey:kUserID];
                    
                    [[self progressHUD] setLabelText:@"Loading Feed..."];
                    
                    [self refreshTableInformation:nil from:0 to:20 removeSplash:YES];
                }
                else {
                    [[self progressHUD] hide:YES];
                    
                    UIAlertView *loginFailedAlert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Your login has failed." cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^{
                        [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
                    }]
                                                                      otherButtonItems:nil, nil];
                    
                    [loginFailedAlert show];
                }
            }
            else {
                [[ActivityManager sharedManager] decrementActivityCount];
                
                [[self progressHUD] hide:YES];
                
                [[self navigationController] popToRootViewControllerAnimated:YES];
                
                [(LoginViewController *)[[self navigationController] topViewController] setDoNotLogin:YES];
            }
            
            [[ActivityManager sharedManager] decrementActivityCount];
        }];
    }
    else {
        if (![self theFeed]) {
            [self refreshTableInformation:nil from:0 to:20 removeSplash:NO];
        }
    }
    
    [super viewDidLoad];
}

- (void)initializeActivityIndicator
{
    if (![self activityIndicator]) {
        [self setActivityIndicator:[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)]];
        
        [[self activityIndicator] setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    }
    
    //FIXME
    //[[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:[self activityIndicator]]];
    
    if (![[self activityIndicator] isAnimating]) {
        [[self activityIndicator] startAnimating];
    }
}

-(void)setupNotifications
{
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kChangeTypeNotification object:nil queue:mainQueue usingBlock:^(NSNotification *number) {
        int i = [[number object] intValue];
        
        if (i == 0) {
            [self setCurrentChangeType:0];
        }
        else if (i == 1) {
            [self setCurrentChangeType:1];
        }
        else if (i == 2) {
            [self setCurrentChangeType:2];
        }
        else {
            NSLog(@"Some kind of madness has happened");
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kRefreshYourTablesNotification object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self initializeActivityIndicator];
        
        [[self externalImageCache] removeAllObjects];
        
        [self refreshTableInformation:nil from:0 to:[[self theFeed] count] removeSplash:NO];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSuccessfulTweetNotification object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setTwitterSuccess:YES];
        
        [[self externalImageCache] removeAllObjects];

        [self checkForFBAndTwitterSucess];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSuccessfulFacebookNotification object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setFbSuccess:YES];
        
        [[self externalImageCache] removeAllObjects];

        [self checkForFBAndTwitterSucess];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kFacebookOrTwitterCurrentlySending object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self initializeActivityIndicator];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kStopAnimatingActivityIndicator object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        if ([[self activityIndicator] isAnimating]) {
            [[self activityIndicator] stopAnimating];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPostOnlyToJukaela object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setJustToJukaela:YES];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kShowImage object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self showImage:aNotification];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPostImage object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        UIImage *temp = [aNotification userInfo][kImageNotification];
        
        [self setTempImage:temp];
        
        [self performSegueWithIdentifier:kShowPostView sender:self];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLoadUserWithUsernameNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        NSString *usernameString = [aNotification userInfo][@"username"];
        
        [self requestWithUsername:usernameString];
    }];
}

-(void)showImage:(NSNotification *)aNotification
{
    if ([kAppDelegate currentViewController] == self) {
        NSIndexPath *indexPath = [aNotification userInfo][kIndexPath];
        
        NSURL *tempURL = [NSURL URLWithString:[self theFeed][[indexPath row]][kImageURL]];
        
        NSMutableURLRequest *request = [NSURLRequest requestWithURL:tempURL];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                
                PhotoViewerViewController *viewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ShowPhotos"];
                
                [viewController setMainImage:[UIImage imageWithData:data]];
                
                UIImage *tempImage = [[self imageWithView:[self view]] applyBlurWithRadius:10 tintColor:[UIColor clearColor] saturationDeltaFactor:1.0 maskImage:nil];
                
                [viewController setBackgroundImage:tempImage];
                
                [self presentViewController:viewController animated:YES completion:nil];
            }
            else {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                     message:@"There has been an error downloading the requested image."
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil, nil];
                
                [errorAlert show];
            }
        }];

    }
}

-(void)switchToSelectedUser:(NSNotification *)aNotification
{
    if ([kAppDelegate currentViewController] == self) {
        if (![self progressHUD]) {
            [self setProgressHUD:[[MBProgressHUD alloc] initWithWindow:[[self view] window]]];
        }
        
        [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
        [[self progressHUD] setLabelText:@"Loading User..."];
        [[self progressHUD] setDelegate:self];
        
        [[[self view] window] addSubview:[self progressHUD]];
        
        [[self progressHUD] show:YES];
        
        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][kIndexPath];
        
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = nil;
        
        if ([self theFeed][[indexPathOfTappedRow row]][kOriginalPosterID] && [self theFeed][[indexPathOfTappedRow row]][kOriginalPosterID] != [NSNull null]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][kOriginalPosterID]]];
        }
        else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][kUserID]]];
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
            }
            else {
                [Helpers errorAndLogout:self withMessage:@"There was an error loading the user.  Please logout and log back in."];
            }
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [[self progressHUD] hide:YES];
            
            [self performSegueWithIdentifier:kShowUser sender:nil];
        }];
    }
}

-(void)checkForFBAndTwitterSucess
{
    if (([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) && ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference] == NO)) {
        if ([self twitterSuccess]) {
            WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Posting Complete!"];
            
            [successNotice show];
            
            [self setTwitterSuccess:NO];
            
            [[self activityIndicator] stopAnimating];
        }
    }
    else if (([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) && ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference] == NO)) {
        if ([self fbSuccess]) {
            WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Posting Complete!"];
            
            [successNotice show];
            
            [self setFbSuccess:NO];
            
            [[self activityIndicator] stopAnimating];
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference] && [[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
        if ([self twitterSuccess] && [self fbSuccess]) {
            WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Posting Complete!"];
            
            [successNotice show];
            
            [self setTwitterSuccess:NO];
            [self setFbSuccess:NO];
            
            [[self activityIndicator] stopAnimating];
        }
    }
    else {
        return;
    }
}

-(void)composePost:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:kShowPostView sender:self];
}

-(void)refreshTableInformation:(NSIndexPath *)indexPath from:(NSInteger)from to:(NSInteger)to removeSplash:(BOOL)removeSplash
{
    if (!from) {
        from = 0;
    }
    
    if (!to) {
        to = 20;
    }
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory feedRequestFrom:from to:to];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [ObjectMapper convertToFeedItemObject:data];
            
            NSArray *oldArray = [self theFeed];
            
            [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
            
            NSMutableSet *firstSet = [NSMutableSet setWithArray:[self theFeed]];
            NSMutableSet *secondSet = [NSMutableSet setWithArray:[self theFeed]];
            
            [firstSet unionSet:[NSSet setWithArray:oldArray]];
            [secondSet intersectSet:[NSSet setWithArray:oldArray]];
            
            [firstSet minusSet:secondSet];
            
            NSInteger difference = [firstSet count];
            
            if ([self currentChangeType] == INSERT_POST) {
                if ([self justToJukaela]) {
                    [[self activityIndicator] stopAnimating];
                    
                    [self setJustToJukaela:NO];
                }
                
                @try {
                    [[self tableView] beginUpdates];
                    
                    if (difference > 2) {
                        difference /= 2;
                    }
                    else if (difference == 2) {
                        difference = 1;
                    }
                    
                    for (int i = 0; i < difference; i++) {
                        [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                        
                        [[self tableView] deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:(to - 1) - i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    }
                    
                    [[self tableView] endUpdates];
                }
                @catch (NSException *exception) {
                    if (exception) {
                        NSLog(@"%@", exception);
                        NSLog(@"Crazy things just happened with the integrity of this table, yo");
                    }
                    
                    UIAlertView *tableError = [[UIAlertView alloc] initWithTitle:@"Table Integrity Issue!" message:[NSString stringWithFormat:@"Table has been restored.  Error %i", difference] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    
                    [tableError show];
                    
                    [self setCurrentChangeType:-1];
                    
                    [self setTheFeed:nil];
                    
                    [self refreshTableInformation:nil from:0 to:20 removeSplash:NO];
                }
                @finally {
                    NSLog(@"Inside finally");
                }
                
            }
            else if ([self currentChangeType] == DELETE_POST) {
                @try {
                    [[self tableView] beginUpdates];
                    [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:19 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    
                    [[self tableView] endUpdates];
                }
                @catch (NSException *exception) {
                    if (exception) {
                        NSLog(@"%@", exception);
                        NSLog(@"Crazy things just happened with the integrity of this table, yo");
                        
                        [self setCurrentChangeType:-1];
                        
                        [self setTheFeed:nil];
                        
                        [self refreshTableInformation:nil from:0 to:20 removeSplash:NO];
                    }
                }
                @finally {
                    NSLog(@"Inside finally");
                }
                
            }
            else {
                if ([[self activityIndicator] isAnimating]) {
                    [[self activityIndicator] stopAnimating];
                }
                
                [[self tableView] reloadData];
            }
            
            [self setCurrentChangeType:-1];
            
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [[self refreshControl] endRefreshing];
        }
        else {
            WBErrorNoticeView *notice = [[WBErrorNoticeView alloc] initWithView:[self view] title:@"Error reloading Feed"];
            
            [notice show];
        }
        
        if (![[self progressHUD] isHidden]) {
            [[self progressHUD] hide:YES];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
    }];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentText = [self theFeed][[indexPath row]][kContent];
    
    CGSize constraint = CGSizeMake(300, 20000);
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIColor *color = [UIColor blackColor];
    
    NSDictionary *attrDict = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:contentText attributes:attrDict];
    
    CGRect rect = [string boundingRectWithSize:constraint options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        
    if ([self theFeed][[indexPath row]][kRepostUserID] && [self theFeed][[indexPath row]][kRepostUserID] != [NSNull null]) {
        return rect.size.height + 50 + 10 + 20;
    }
    else {
        return rect.size.height + 50 + 10;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_theFeed count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FeedViewCell";
    static NSString *CellWithImageCellIdentifier = @"CellWithImageCellIdentifier";
    
    id cell = nil;
    
    if ([self theFeed][[indexPath row]][kImageURL] && [self theFeed][[indexPath row]][kImageURL] != [NSNull null]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellWithImageCellIdentifier];
        
        if (!cell) {
            cell = [[NormalWithImageCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellWithImageCellIdentifier withTableView:tableView];
            
            [cell setBackgroundView:[[CellBackground alloc] init]];
        }
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (!cell) {
            cell = [[NormalCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier withTableView:tableView];
            
            [cell setBackgroundView:[[CellBackground alloc] init]];
        }
    }
    
    if ([self theFeed][[indexPath row]][kImageURL] && [self theFeed][[indexPath row]][kImageURL] != [NSNull null]) {
        NSMutableString *tempString = [NSMutableString stringWithString:[self theFeed][[indexPath row]][kImageURL]];
        
        NSString *tempExtensionString = [NSString stringWithFormat:@".%@", [tempString pathExtension]];
        
        [tempString stringByReplacingOccurrencesOfString:tempExtensionString withString:@""];
        [tempString appendFormat:@"s"];
        [tempString appendString:tempExtensionString];
        
        if (![[cell externalImage] image]) {
            if ([[self externalImageCache] objectForKey:indexPath]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                    UIImage *tempImage = [[[self externalImageCache] objectForKey:indexPath] thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[cell externalImage] setImage:tempImage];
                    });
                });
            }
            else if ([[NSFileManager defaultManager] fileExistsAtPath:[[self documentsFolder] stringByAppendingPathComponent:[tempString lastPathComponent]]]) {
                UIImage *externalImageFromDisk = [UIImage imageWithData:[NSData dataWithContentsOfFile:[[Helpers documentsPath] stringByAppendingPathComponent:[tempString lastPathComponent]]]];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                    UIImage *tempImage = [externalImageFromDisk thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[cell externalImage] setImage:tempImage];
                    });
                });
                                
                if (externalImageFromDisk) {
                    [[self externalImageCache] setObject:externalImageFromDisk forKey:indexPath];
                }
            }
            else {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
                
                objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
                
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
                    
                    if (image) {
                        [[self externalImageCache] setObject:image forKey:indexPath];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[cell externalImage] setImage:[image thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh]];
                        
                        [Helpers saveImage:image withFileName:[tempString lastPathComponent]];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            NSString *path = [[self documentsFolder] stringByAppendingPathComponent:[NSString stringWithString:[tempString lastPathComponent]]];
                            
                            NSData *data = nil;
                            
                            if ([[tempString pathExtension] isEqualToString:@".png"]) {
                                data = UIImagePNGRepresentation(image);
                            }
                            else {
                                data = UIImageJPEGRepresentation(image, 1.0);
                            }
                            
                            [data writeToFile:path atomically:YES];
                        });
                    });
                });
            }
        }
    }
        
    if ([self theFeed][[indexPath row]][kContent]) {
        [[cell contentText] setText:[self theFeed][[indexPath row]][kContent]];
    }
    else {
        [[cell contentText] setText:@"Loading..."];
    }
    
    if ([self theFeed][[indexPath row]][kName] && [self theFeed][[indexPath row]][kName] != [NSNull null]) {
        [[cell nameLabel] setText:[self theFeed][[indexPath row]][kName]];
    }
    else {
        if ([self nameDict][[self theFeed][[indexPath row]][kUserID]]) {
            [[cell nameLabel] setText:[NSString stringWithFormat:@"%@", [self nameDict][[self theFeed][[indexPath row]][kUserID]]]];
        }
        else {
            [[cell nameLabel] setText:@"Loading..."];
        }
    }
    
    if ([self theFeed][[indexPath row]][kUsername] && [self theFeed][[indexPath row]][kUsername] != [NSNull null]) {
        [[cell usernameLabel] setText:[NSString stringWithFormat:@"@%@", [self theFeed][[indexPath row]][kUsername]]];
    }
    
    if ([self theFeed][[indexPath row]][kRepostUserID] && [self theFeed][[indexPath row]][kRepostUserID] != [NSNull null]) {
        [[cell repostedNameLabel] setUserInteractionEnabled:YES];
        
        CGSize contentSize;
        
        if ([self theFeed][[indexPath row]][kImageURL] && [self theFeed][[indexPath row]][kImageURL] != [NSNull null]) {
            contentSize = [[self theFeed][[indexPath row]][kContent] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                                constrainedToSize:CGSizeMake(185 - (7.5 * 2), 20000)
                                                                    lineBreakMode:NSLineBreakByWordWrapping];
        }
        else {
            contentSize = [[self theFeed][[indexPath row]][kContent] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                                constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                    lineBreakMode:NSLineBreakByWordWrapping];
        }
        CGSize nameSize = [[self theFeed][[indexPath row]][kName] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
                                                             constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                 lineBreakMode:NSLineBreakByWordWrapping];
        
        CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 85);
        
        [[cell repostedNameLabel] setFrame:CGRectMake(7, height - 5, 228, 20)];
        
        [[cell repostedNameLabel] setText:[NSString stringWithFormat:@"Reposted by %@", [self theFeed][[indexPath row]][kRepostName]]];
    }
    else {
        [[cell repostedNameLabel] setUserInteractionEnabled:NO];
    }
    
    [cell setDate:[self theFeed][[indexPath row]][kCreationDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][kUserID]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[self documentsFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][kUserID]]]] error:nil];
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetween:[NSDate date] and:attributes[NSFileCreationDate]] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self theFeed][[indexPath row]][kEmail] withSize:40]]];
                    
#if (TARGET_IPHONE_SIMULATOR)
                    image = [JEImages normalize:image];
#endif
                    UIImage *resizedImage = [image thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
                        
                        if ([indexPath isEqual:cellIndexPath]) {
                            [[cell imageView] setImage:resizedImage];
                            [cell setNeedsDisplay];
                        }
                        
                        [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][kUserID]]];
                    });
                });
            }
        }
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self theFeed][[indexPath row]][kEmail] withSize:40]]];
            
#if (TARGET_IPHONE_SIMULATOR)
            image = [JEImages normalize:image];
#endif
            UIImage *resizedImage = [image thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
                
                if ([indexPath isEqual:cellIndexPath]) {
                    [[cell imageView] setImage:resizedImage];
                    [cell setNeedsDisplay];
                }
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][kUserID]]];
            });
        });
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == ([[self theFeed] count] - 1)) {
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
        
        NSString *requestString = [RequestFactory feedRequestFrom:[[self theFeed] count] to:[[self theFeed] count] + 20];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [self initializeActivityIndicator];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                NSMutableArray *tempArray = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
                
                NSInteger oldTableViewCount = [[self theFeed] count];
                
                NSMutableArray *rehashOfOldArray = [NSMutableArray arrayWithArray:[self theFeed]];
                
                [rehashOfOldArray addObjectsFromArray:tempArray];
                
                [self setTheFeed:rehashOfOldArray];
                
                @try {
                    [[self tableView] beginUpdates];
                    
                    int tempArrayCount = [tempArray count];
                    
                    for (int i = 0; i < tempArrayCount; i++) {
                        NSInteger rowInt = oldTableViewCount + i;
                        
                        [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowInt inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    }
                    [[self tableView] endUpdates];
                }
                @catch (NSException *exception) {
                    if (exception) {
                        NSLog(@"%@", exception);
                    }
                    
                    [[self tableView] reloadData];
                }
                @finally {
                    [[self activityIndicator] stopAnimating];
                    
                    NSLog(@"Inside finally");
                }
            }
            else {
                WBErrorNoticeView *notice = [[WBErrorNoticeView alloc] initWithView:[self view] title:@"Error reloading Feed"];
                
                [notice show];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
        }];
        [[ActivityManager sharedManager] decrementActivityCount];
    }
}

-(void)doubleTap:(NSNotification *)aNotification
{
    RIButtonItem *likeButton = nil;
    RIButtonItem *usersWhoLiked = nil;
    RIButtonItem *replyButton = nil;
    RIButtonItem *showThread = nil;
    RIButtonItem *deleteThread = nil;
    RIButtonItem *cancelButton = nil;
    
    if ([kAppDelegate currentViewController] == self) {
        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][kIndexPath];
        
        [self setTempIndexPath:indexPathOfTappedRow];
                
        if (![[NSString stringWithFormat:@"%@", [self theFeed][[indexPathOfTappedRow row]][kUserID]] isEqualToString:[kAppDelegate userID]]) {
            BOOL addTheLikeButton = YES;
            
            if ([self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] && [self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] != [NSNull null]) {
                for (NSDictionary *userWhoLiked in [self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"]) {
                    if ([[userWhoLiked[@"user_id"] stringValue] isEqualToString:[kAppDelegate userID]]) {
                        addTheLikeButton = NO;
                    }
                }
            }
            
            if (addTheLikeButton) {
                likeButton = [RIButtonItem itemWithLabel:@"Like" action:^{
                    [[ActivityManager sharedManager] incrementActivityCount];
                    
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@/like.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][kID]]];
                    
                    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
                    
                    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                        [self refreshControlRefresh:nil];
                        
                        [[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow] setSelected:NO animated:YES];
                        
                        WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Liked!"];
                        
                        [successNotice show];
                        
                        [[ActivityManager sharedManager] decrementActivityCount];
                    }];
                }];
            }
        }
        
        if ([self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] && [self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] != [NSNull null] && (unsigned long)[(NSArray *)[self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] count] > 0) {
            NSString *pluralization = nil;
            
            if ((unsigned long)[(NSArray *)[self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] count] == 1) {
                pluralization = @"Like";
            }
            else if ((unsigned long)[(NSArray *)[self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] count] > 1) {
                pluralization = @"Likes";
            }
            
            usersWhoLiked = [RIButtonItem itemWithLabel:[NSString stringWithFormat:@"%lu %@", (unsigned long)[(NSArray *)[self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] count], pluralization] action:^{
                [self setTempArray:[self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"]];
                
                [self performSegueWithIdentifier:@"UsersWhoLiked" sender:self];
            }];
        }
        
        replyButton = [RIButtonItem itemWithLabel:@"Reply" action:^{
            [self performSegueWithIdentifier:kShowReplyView sender:self];
        }];
        
        if ([self theFeed][[indexPathOfTappedRow row]][@"in_reply_to"] != [NSNull null]) {
            showThread = [RIButtonItem itemWithLabel:@"Show Thread" action:^{
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@/thread_for_micropost.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][kID]]];
                
                NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
                
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    [self setTempArray:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
                    
                    [self performSegueWithIdentifier:kShowThread sender:self];
                }];
            }];
        }
        
        if ([[NSString stringWithFormat:@"%@", [self theFeed][[indexPathOfTappedRow row]][kUserID]] isEqualToString:[kAppDelegate userID]]) {
            deleteThread = [RIButtonItem itemWithLabel:@"Delete Post" action:^{
                [[ActivityManager sharedManager] incrementActivityCount];
                
                NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
                
                [tempCell disableCell];
                
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][kID]]];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
                
                [request setHTTPMethod:@"DELETE"];
                [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
                [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
                
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    [[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow] setSelected:NO animated:YES];
                    
                    [self setCurrentChangeType:DELETE_POST];
                    
                    [self refreshTableInformation:indexPathOfTappedRow from:0 to:[[self theFeed] count] removeSplash:NO];
                    
                    [[ActivityManager sharedManager] decrementActivityCount];
                }];
            }];
        }
        
        cancelButton = [RIButtonItem itemWithLabel:@"Cancel" action:^{
            [[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow] setSelected:NO animated:YES];
            
            return;
        }];
        
        UIActionSheet *cellActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelButton destructiveButtonItem:deleteThread otherButtonItems:replyButton, likeButton, usersWhoLiked, showThread, nil];

        [cellActionSheet showInView:[self view]];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:kShowUser]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ShowUserViewController *viewController = (ShowUserViewController *)[navigationController topViewController];
                
        [viewController setUserDict:_tempDict];
    }
    else if ([[segue identifier] isEqualToString:kShowPostView]) {
        UINavigationController *navigationController = [segue destinationViewController];
        PostViewController *viewController = (PostViewController *)[navigationController topViewController];
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:[[self view] frame]];
        
        UIImage *tempImage = [self imageWithView:[self view]];
        
        [tempImageView setImage:tempImage];
        
        [[viewController view] insertSubview:tempImageView belowSubview:[viewController backgroundView]];
        
        if ([self tempImage]) {
            [viewController setImageFromExternalSource:[self tempImage]];
        }
                
        [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowReplyView]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:[[self view] frame]];
        
        UIImage *tempImage = [self imageWithView:[self view]];
        
        [tempImageView setImage:tempImage];
        
        [[viewController view] insertSubview:tempImageView belowSubview:[viewController backgroundView]];
        
        NSDictionary *tempDict = [self theFeed][[[self tempIndexPath] row]];
    
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", tempDict[kUsername]]];
        [viewController setInReplyTo:tempDict[kID]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowRepostView]) {
        UITableViewCell *tempCell = [[self tableView] cellForRowAtIndexPath:[self tempIndexPath]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setRepostString:[NSString stringWithFormat:@"%@", [[tempCell textLabel] text]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowThread]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ThreadedPostsViewController *viewController = (ThreadedPostsViewController *)[navigationController topViewController];
        
        [viewController setThreadedPosts:[self tempArray]];
    }
    else if ([[segue identifier] isEqualToString:@"UsersWhoLiked"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        UsersWhoLikedViewController *viewController = (UsersWhoLikedViewController *)[navigationController topViewController];
        
        [viewController setUsersArray:[self tempArray]];
    }
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

- (void)handleURL:(NSURL*)url
{
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[url absoluteString]];
    
    [webViewController setBarsTintColor:[UIColor darkGrayColor]];
    
    [self presentViewController:webViewController animated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultFailed) {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error sending your email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            
        [errorAlert show];
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

-(void)refreshControlRefresh:(id)sender
{
    [self initializeActivityIndicator];
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory feedRequestFrom:0 to:[[self theFeed] count] - 1];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            int oldNumberOfPosts = [[self theFeed] count];
            
            [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
            
            int newNumberOfPosts = [[self theFeed] count];
            
            if (newNumberOfPosts > oldNumberOfPosts) {
                NSString *tempString;
                
                if ((newNumberOfPosts - oldNumberOfPosts) == 1) {
                    tempString = @"Post";
                }
                else {
                    tempString = @"Posts";
                }
                
                WBStickyNoticeView *notice = [WBStickyNoticeView stickyNoticeInView:[self view]
                                                                              title:[NSString stringWithFormat:@"%d New %@", (newNumberOfPosts - oldNumberOfPosts), tempString]];
                
                [notice show];
            }
            [[self tableView] reloadData];
        }
        else {
            WBErrorNoticeView *notice = [[WBErrorNoticeView alloc] initWithView:[self view] title:@"Error reloading Feed"];
            
            [notice show];
        }
        
        [[self refreshControl] endRefreshing];
        
        [[self activityIndicator] stopAnimating];
        
        [[ActivityManager sharedManager] decrementActivityCount];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
    }];
}

-(void)requestWithUsername:(NSString *)username
{
    if ([kAppDelegate currentViewController] == self) {
        if (![self progressHUD]) {
            [self setProgressHUD:[[MBProgressHUD alloc] initWithWindow:[[self view] window]]];
        }
        [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
        [[self progressHUD] setLabelText:@"Loading User..."];
        [[self progressHUD] setDelegate:self];
        
        [[[self view] window] addSubview:[self progressHUD]];
        
        [[self progressHUD] show:YES];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/user_from_username.json", kSocialURL]];
        
        NSString *requestString = [RequestFactory userFromUsername:username];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
            }
            else {
                [Helpers errorAndLogout:self withMessage:@"There was an error loading the user.  Please logout and log back in."];
            }
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [[self progressHUD] hide:YES];
            
            [self performSegueWithIdentifier:kShowUser sender:nil];
        }];
    }
}

-(void)didReceiveMemoryWarning
{
    [[self externalImageCache] removeAllObjects];
    
    [super didReceiveMemoryWarning];
}

@end
