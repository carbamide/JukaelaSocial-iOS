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
#import "PostViewController.h"
#import "SFHFKeychainUtils.h"
#import "ShareObject.h"
#import "ShowUserViewController.h"
#import "SVModalWebViewController.h"
#import "ThreadedPostsViewController.h"
#import "UIImageView+Curled.h"
#import "UsersWhoLikedViewController.h"
#import "WBErrorNoticeView.h"
#import "WBStickyNoticeView.h"
#import "WBSuccessNoticeView.h"
#import "YISplashScreen.h"

@interface FeedViewController ()
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (strong, nonatomic) NSMutableArray *tempArray;
@property (strong, nonatomic) NSString *documentsFolder;
@property (strong, nonatomic) NSString *stringToPost;
@property (strong, nonatomic) NSTimer *refreshTimer;
@property (strong, nonatomic) UIImage *tempImage;

@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) YIFullScreenScroll *fullScreenDelegate;

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
    
    [_fullScreenDelegate layoutTabBarController];
    
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
    
    JRefreshControl *refreshControl = [[JRefreshControl alloc] init];
    
    [refreshControl setTintColor:[UIColor blackColor]];
    
    [refreshControl addTarget:self action:@selector(refreshControlRefresh:) forControlEvents:UIControlEventValueChanged];
    
    [self setRefreshControl:refreshControl];
    
    _fullScreenDelegate = [[YIFullScreenScroll alloc] initWithViewController:self];
    
    [self setDocumentsFolder:[Helpers documentsPath]];
    
    [self setupNotifications];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
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
                NSDictionary *loginDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
                
                if (loginDict) {
                    [[[[self tabBarController] tabBar] items][1] setEnabled:YES];
                    [[[[self tabBarController] tabBar] items][2] setEnabled:YES];
                    [[[[self tabBarController] tabBar] items][3] setEnabled:YES];
                    [[[[self tabBarController] tabBar] items][4] setEnabled:YES];
                    
                    [kAppDelegate setUserID:[NSString stringWithFormat:@"%@", loginDict[kID]]];
                    [kAppDelegate setUserEmail:[NSString stringWithFormat:@"%@", loginDict[kEmail]]];
                    [kAppDelegate setUserUsername:[NSString stringWithFormat:@"%@", loginDict[kUsername]]];
                    
                    [[NSUserDefaults standardUserDefaults] setValue:[kAppDelegate userID] forKey:kUserID];
                    
                    [[self progressHUD] setLabelText:@"Loading Feed..."];
                    
                    [self refreshTableInformation:nil from:0 to:20 removeSplash:YES];
                }
                else {
                    [[self progressHUD] hide:YES];
                    
                    BlockAlertView *loginFailedAlert = [[BlockAlertView alloc] initWithTitle:@"Login Failed" message:@"The login has failed. Sorry!"];
                    
                    [loginFailedAlert setCancelButtonWithTitle:@"OK" block:^{
                        [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
                    }];
                    
                    [loginFailedAlert show];
                }
            }
            else {
                [[ActivityManager sharedManager] decrementActivityCount];
                
                [[self progressHUD] hide:YES];
                
                [YISplashScreen hide];
                
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

-(void)longPress:(UILongPressGestureRecognizer *)aGesture
{
    if ([aGesture state] == UIGestureRecognizerStateBegan) {
        BlockActionSheet *longPressActionSheet = [[BlockActionSheet alloc] initWithTitle:@"Share..."];
        
        [longPressActionSheet addButtonWithTitle:@"Facebook Only" block:^{
            [kAppDelegate setOnlyToFacebook:YES];
            
            [self composePost:nil];
        }];
        
        [longPressActionSheet addButtonWithTitle:@"Twitter Only"  block:^{
            [kAppDelegate setOnlyToTwitter:YES];
            
            [self composePost:nil];
        }];
        
        [longPressActionSheet addButtonWithTitle:@"Jukaela Only" block:^{
            [kAppDelegate setOnlyToJukaela:YES];
            
            [self composePost:nil];
        }];
        
        [longPressActionSheet setCancelButtonWithTitle:@"Cancel" block:nil];
        
        [longPressActionSheet showInView:[self view]];
    }
    
    
}

- (void)initializeActivityIndicator
{
    if (![self activityIndicator]) {
        [self setActivityIndicator:[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)]];
    }
    
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:[self activityIndicator]]];
    
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
        
        [self refreshTableInformation:nil from:0 to:[[self theFeed] count] removeSplash:NO];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSuccessfulTweetNotification object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setTwitterSuccess:YES];
        
        [self checkForFBAndTwitterSucess];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSuccessfulFacebookNotification object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setFbSuccess:YES];
        
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
        [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
        
        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][kIndexPath];
        
        NSURL *urlOfImage = [NSURL URLWithString:[self theFeed][[indexPathOfTappedRow row]][kImageURL]];
        
        MWPhoto *tempPhoto = [MWPhoto photoWithURL:urlOfImage];
        
        [tempPhoto setCaption:[self theFeed][[indexPathOfTappedRow row]][kContent]];
        
        [self setPhotos:@[tempPhoto]];
        
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        
        [browser setDisplayActionButton:YES];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:browser];
        
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return [[self photos] count];
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    if (index < [[self photos] count]) {
        return [[self photos] objectAtIndex:index];
    }
    return nil;
}

-(void)switchToSelectedUser:(NSNotification *)aNotification
{
    if ([kAppDelegate currentViewController] == self) {
        [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
        
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
                [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
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
            NSArray *oldArray = [self theFeed];
            
            [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
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
                    
                    BlockAlertView *tableError = [[BlockAlertView alloc] initWithTitle:@"Table Integrity Issue!" message:[NSString stringWithFormat:@"Table has been restored.  Error %i", difference]];
                    
                    [tableError setCancelButtonWithTitle:@"OK" block:nil];
                    
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
                
                if (removeSplash) {
                    [YISplashScreen hide];
                }
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
    
    CGSize constraint = CGSizeMake(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 750 : 300, 20000);
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont fontWithName:kFontPreference size:17] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    if ([self theFeed][[indexPath row]][kRepostUserID] && [self theFeed][[indexPath row]][kRepostUserID] != [NSNull null]) {
        return contentSize.height + 50 + 10 + 20;
    }
    else {
        return contentSize.height + 50 + 10;
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
            cell = [[NormalWithImageCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellWithImageCellIdentifier];
            
            [cell setBackgroundView:[[CellBackground alloc] init]];
        }
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (!cell) {
            cell = [[NormalCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            
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
                [[cell externalImage] setImage:[[self externalImageCache] objectForKey:indexPath] borderWidth:2 shadowDepth:5 controlPointXOffset:20 controlPointYOffset:25];
            }
            else if ([[NSFileManager defaultManager] fileExistsAtPath:[[self documentsFolder] stringByAppendingPathComponent:[tempString lastPathComponent]]]) {
                UIImage *externalImageFromDisk = [UIImage imageWithData:[NSData dataWithContentsOfFile:[[self documentsFolder] stringByAppendingPathComponent:[tempString lastPathComponent]]]];
                
                [[cell externalImage] setImage:externalImageFromDisk borderWidth:2 shadowDepth:5 controlPointXOffset:20 controlPointYOffset:25];
                
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
                        [[cell externalImage] setImage:image borderWidth:2 shadowDepth:5 controlPointXOffset:20 controlPointYOffset:25];
                        
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
    
    [[cell contentText] setFontName:kFontPreference];
    [[cell contentText] setFontSize:17];
    
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
            contentSize = [[self theFeed][[indexPath row]][kContent] sizeWithFont:[UIFont fontWithName:kFontPreference size:17]
                                                                constrainedToSize:CGSizeMake(185 - (7.5 * 2), 20000)
                                                                    lineBreakMode:NSLineBreakByWordWrapping];
        }
        else {
            contentSize = [[self theFeed][[indexPath row]][kContent] sizeWithFont:[UIFont fontWithName:kFontPreference size:17]
                                                                constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                    lineBreakMode:NSLineBreakByWordWrapping];
        }
        CGSize nameSize = [[self theFeed][[indexPath row]][kName] sizeWithFont:[UIFont fontWithName:kFontPreference size:14]
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
                NSMutableArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
                
                NSInteger oldTableViewCount = [[self theFeed] count];
                
                [[self theFeed] addObjectsFromArray:tempArray];
                
                NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]);
                
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
    if ([kAppDelegate currentViewController] == self) {
        [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
        
        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][kIndexPath];
        
        [self setTempIndexPath:indexPathOfTappedRow];
        
        BlockActionSheet *cellActionSheet = [[BlockActionSheet alloc] initWithTitle:nil];
        
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
                [cellActionSheet addButtonWithTitle:@"Like" block:^{
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
            
            [cellActionSheet addButtonWithTitle:[NSString stringWithFormat:@"%lu %@", (unsigned long)[(NSArray *)[self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"] count], pluralization] block:^{
                [self setTempArray:[self theFeed][[indexPathOfTappedRow row]][@"users_who_liked"]];
                
                [self performSegueWithIdentifier:@"UsersWhoLiked" sender:self];
            }];
        }
        
        [cellActionSheet addButtonWithTitle:@"Reply" block:^{
            [self performSegueWithIdentifier:kShowReplyView sender:self];
        }];
        
        [cellActionSheet addButtonWithTitle:@"Share to Twitter" block:^{
            NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
            
            if ([[[tempCell contentText] text] length] > 140) {
                NSArray *tempArray = [Helpers splitString:[[tempCell contentText] text] maxCharacters:140];
                
                for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                    [ShareObject shareToTwitter:tempString withViewController:self];
                }
            }
            else {
                [ShareObject shareToTwitter:[[tempCell contentText] text] withViewController:self];
            }
        }];
        
        [cellActionSheet addButtonWithTitle:@"Share to Facebook" block:^{
            NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
            
            [ShareObject shareToFacebook:[[tempCell contentText] text] withViewController:self];
        }];
        
        [cellActionSheet addButtonWithTitle:@"Share via Mail" block:^{
            NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
            
            [ShareObject sharePostViaMail:tempCell withViewController:self];
        }];
        
        if ([self theFeed][[indexPathOfTappedRow row]][@"in_reply_to"] != [NSNull null]) {
            [cellActionSheet addButtonWithTitle:@"Show Thread" block:^{
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@/thread_for_micropost.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][kID]]];
                
                NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
                
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    [self setTempArray:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
                    
                    [self performSegueWithIdentifier:kShowThread sender:self];
                }];
            }];
        }
        
        if ([[NSString stringWithFormat:@"%@", [self theFeed][[indexPathOfTappedRow row]][kUserID]] isEqualToString:[kAppDelegate userID]]) {
            [cellActionSheet setDestructiveButtonWithTitle:@"Delete Post" block:^{
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
        
        [cellActionSheet setCancelButtonWithTitle:@"Cancel" block:^{
            [[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow] setSelected:NO animated:YES];
            
            return;
        }];
        
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
        if ([self tempImage]) {
            UINavigationController *navigationController = [segue destinationViewController];
            PostViewController *viewController = (PostViewController *)[navigationController topViewController];
            
            [viewController setImageFromExternalSource:[self tempImage]];
            [viewController setModalPresentationStyle:UIModalPresentationFormSheet];
        }
        
        [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowReplyView]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [self theFeed][[[self tempIndexPath] row]][kUsername]]];
        [viewController setInReplyTo:[self theFeed][[[self tempIndexPath] row]][kID]];
        
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
    [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
    
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[url absoluteString]];
    
    [webViewController setBarsTintColor:[UIColor darkGrayColor]];
    
    [self presentViewController:webViewController animated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultFailed) {
        BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:@"There was an error sending your email"];
        
        [errorAlert setCancelButtonWithTitle:@"OK" block:nil];
        
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
            
            [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_fullScreenDelegate scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_fullScreenDelegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [_fullScreenDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    return [_fullScreenDelegate scrollViewShouldScrollToTop:scrollView];;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [_fullScreenDelegate scrollViewDidScrollToTop:scrollView];
}

-(void)requestWithUsername:(NSString *)username
{
    if ([kAppDelegate currentViewController] == self) {
        [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
        
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
                [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
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
