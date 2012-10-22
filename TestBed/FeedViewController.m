//
//  FeedViewController.m
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//
#import <Accounts/Accounts.h>
#import <objc/runtime.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_1
#import <Social/Social.h>
#endif
#import <Twitter/Twitter.h>
#import "AHMarkedHyperlink.h"
#import "AppDelegate.h"
#import "NormalCellView.h"
#import "FeedViewController.h"
#import "GradientView.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "PostViewController.h"
#import "SelfCellView.h"
#import "ShareObject.h"
#import "ShowUserViewController.h"
#import "SORelativeDateTransformer.h"
#import "SVModalWebViewController.h"
#import "WBErrorNoticeView.h"
#import "WBSuccessNoticeView.h"
#import "WBStickyNoticeView.h"
#import "SFHFKeychainUtils.h"
#import "YISplashScreen.h"
#import "SelfWithImageCellView.h"
#import "UIImageView+Curled.h"
#import "NormalWithImageCellView.h"
#import "LoginViewController.h"

@interface FeedViewController ()
@property (strong, nonatomic) NSString *stringToPost;
@property (strong, nonatomic) ODRefreshControl *oldRefreshControl;
@property (nonatomic) ChangeType currentChangeType;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (nonatomic) BOOL fbSuccess;
@property (nonatomic) BOOL twitterSuccess;
@property (nonatomic) BOOL jukaelaSuccess;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (nonatomic) BOOL justToJukaela;
@property (strong, nonatomic) NSTimer *refreshTimer;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) UIImage *tempImage;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doubleTap:) name:@"double_tap" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToSelectedUser:) name:@"send_to_user" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repostSwitchToSelectedUser:) name:@"repost_send_to_user" object:nil];
    
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"double_tap" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"send_to_user" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"repost_send_to_user" object:nil];
    
    [super viewDidDisappear:animated];
}

-(void)viewDidLoad
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        
        [refreshControl setTintColor:[UIColor blackColor]];
        
        [refreshControl addTarget:self action:@selector(refreshControlRefresh:) forControlEvents:UIControlEventValueChanged];
        
        [self setRefreshControl:refreshControl];
    }
    else {
        _oldRefreshControl = [[ODRefreshControl alloc] initInScrollView:[self tableView]];
        
        [_oldRefreshControl setTintColor:[UIColor blackColor]];
        
        [_oldRefreshControl addTarget:self action:@selector(refreshControlRefresh:) forControlEvents:UIControlEventValueChanged];
    }
    
    [self setupNotifications];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composePost:)];
    
    [[self navigationItem] setRightBarButtonItem:composeButton];
    
    [[self navigationItem] setHidesBackButton:YES];
    
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    
    [gesture setDelegate:self];
    
    [[[[self navigationItem] rightBarButtonItem] valueForKey:@"view"] addGestureRecognizer:gesture];
    
    [self setCurrentChangeType:-1];
    
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    if ([self loadedDirectly] && [[NSUserDefaults standardUserDefaults] boolForKey:@"read_username_from_defaults"] == YES) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSError *error = nil;
        
        NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
        NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"Jukaela Social" error:&error];
        
        if (![self progressHUD]) {
            [self setProgressHUD:[[MBProgressHUD alloc] initWithView:[self view]]];
        }
        [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
        [[self progressHUD] setLabelText:@"Logging in..."];
        [[self progressHUD] setDelegate:self];
        
        [[self view] addSubview:[self progressHUD]];
        
        [[self progressHUD] show:YES];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/sessions.json", kSocialURL]];
        
        NSString *requestString = [NSString stringWithFormat:@"{ \"session\": {\"email\" : \"%@\", \"password\" : \"%@\", \"apns\": \"%@\"}}", username, password, [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"]];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                NSDictionary *loginDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
                
                if (loginDict) {
                    [[[[self tabBarController] tabBar] items][1] setEnabled:YES];
                    [[[[self tabBarController] tabBar] items][2] setEnabled:YES];
                    [[[[self tabBarController] tabBar] items][3] setEnabled:YES];
                    
                    [kAppDelegate setUserID:[NSString stringWithFormat:@"%@", loginDict[@"id"]]];
                    
                    [[NSUserDefaults standardUserDefaults] setValue:[kAppDelegate userID] forKey:@"user_id"];
                    
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
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                [[self progressHUD] hide:YES];
                
                [YISplashScreen hide];
                
                [[self navigationController] popToRootViewControllerAnimated:YES];
                
                [(LoginViewController *)[[self navigationController] topViewController] setDoNotLogin:YES];
            }
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }];
    }
    else {
        if (![self theFeed]) {
            [self refreshTableInformation:nil from:0 to:20 removeSplash:NO];
        }
        
        if ([[self theFeed] count] == 0) {
            BlockAlertView *noposts = [[BlockAlertView alloc] initWithTitle:@"No Posts" message:@"There are no posts in your feed!  Oh no!  Go to the Users tab and follow someone!"];
            
            [noposts addButtonWithTitle:@"OK" block:nil];
            
            [noposts show];
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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"set_change_type" object:nil queue:mainQueue usingBlock:^(NSNotification *number) {
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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"refresh_your_tables" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self initializeActivityIndicator];
        
        [self refreshTableInformation:nil from:0 to:[[self theFeed] count] removeSplash:NO];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"tweet_successful" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setTwitterSuccess:YES];
        
        [self checkForFBAndTwitterSucess];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"facebook_successful" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setFbSuccess:YES];
        
        [self checkForFBAndTwitterSucess];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"facebook_or_twitter_sending" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self initializeActivityIndicator];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"stop_animating" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        if ([[self activityIndicator] isAnimating]) {
            [[self activityIndicator] stopAnimating];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"just_to_jukaela" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setJustToJukaela:YES];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"show_image" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self showImage:aNotification];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"post_image" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        UIImage *temp = [aNotification userInfo][@"image"];
        
        [self setTempImage:temp];
        
        [self performSegueWithIdentifier:@"ShowPostView" sender:self];
    }];
}

-(void)showImage:(NSNotification *)aNotification
{
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    NSURL *urlOfImage = [NSURL URLWithString:[self theFeed][[indexPathOfTappedRow row]][@"image_url"]];
    
    MWPhoto *tempPhoto = [MWPhoto photoWithURL:urlOfImage];
    
    [tempPhoto setCaption:[self theFeed][[indexPathOfTappedRow row]][@"content"]];
    
    [self setPhotos:@[tempPhoto]];
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    [browser setDisplayActionButton:YES];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:browser];
    
    [self presentViewController:navController animated:YES completion:nil];
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
    if (![self progressHUD]) {
        [self setProgressHUD:[[MBProgressHUD alloc] initWithView:[self view]]];
    }
    [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
    [[self progressHUD] setLabelText:@"Loading User..."];
    [[self progressHUD] setDelegate:self];
    
    [[self view] addSubview:[self progressHUD]];
    
    [[self progressHUD] show:YES];
    
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = nil;
    
    if ([self theFeed][[indexPathOfTappedRow row]][@"original_poster_id"] && [self theFeed][[indexPathOfTappedRow row]][@"original_poster_id"] != [NSNull null]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][@"original_poster_id"]]];
    }
    else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][@"user_id"]]];
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
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [[self progressHUD] hide:YES];
        
        [self performSegueWithIdentifier:@"ShowUser" sender:nil];
    }];
}

-(void)repostSwitchToSelectedUser:(NSNotification *)aNotification
{
    if (![self progressHUD]) {
        [self setProgressHUD:[[MBProgressHUD alloc] initWithView:[self view]]];
    }
    [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
    [[self progressHUD] setLabelText:@"Loading User..."];
    [[self progressHUD] setDelegate:self];
    
    [[self view] addSubview:[self progressHUD]];
    
    [[self progressHUD] show:YES];
    
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][@"repost_user_id"]]];
    
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
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [[self progressHUD] hide:YES];
        
        [self performSegueWithIdentifier:@"ShowUser" sender:nil];
    }];
}

-(void)checkForFBAndTwitterSucess
{
    if (([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) && ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == NO)) {
        if ([self twitterSuccess]) {
            WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Posting Complete!"];
            
            [successNotice show];
            
            [self setTwitterSuccess:NO];
            
            [[self activityIndicator] stopAnimating];
        }
    }
    else if (([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) && ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == NO)) {
        if ([self fbSuccess]) {
            WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Posting Complete!"];
            
            [successNotice show];
            
            [self setFbSuccess:NO];
            
            [[self activityIndicator] stopAnimating];
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
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
    [self performSegueWithIdentifier:@"ShowPostView" sender:self];
}

-(void)refreshTableInformation:(NSIndexPath *)indexPath from:(NSInteger)from to:(NSInteger)to removeSplash:(BOOL)removeSplash
{
    if (!from) {
        from = 0;
    }
    
    if (!to) {
        to = 20;
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"first\" : \"%i\", \"last\" : \"%i\"}", from, to];
    
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
                    
                    NSLog(@"%i", difference);
                    
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
                [[self tableView] beginUpdates];
                [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:19 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                
                [[self tableView] endUpdates];
            }
            else {
                if ([[self activityIndicator] isAnimating]) {
                    [[self activityIndicator] stopAnimating];
                }
                
                [[self tableView] reloadData];
                
                if (removeSplash) {
                    [YISplashScreen hide];
                    
                    UIWindow *tempWindow = [kAppDelegate window];
                    
                    if ([[UIApplication sharedApplication] statusBarFrame].size.height > 20) {
                        [[kAppDelegate window] setFrame:CGRectMake(tempWindow.frame.origin.x, tempWindow.frame.origin.y + 40, tempWindow.frame.size.width, tempWindow.frame.size.height - 40)];
                    }
                    else {
                        [[kAppDelegate window] setFrame:CGRectMake(tempWindow.frame.origin.x, tempWindow.frame.origin.y + 20, tempWindow.frame.size.width, tempWindow.frame.size.height - 20)];
                    }
                    
                    [[UIApplication sharedApplication] setStatusBarHidden:NO];
                }
            }
            
            [self setCurrentChangeType:-1];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
                [[self refreshControl] endRefreshing];
            }
            else {
                [_oldRefreshControl endRefreshing];
            }
        }
        else {
            WBErrorNoticeView *notice = [[WBErrorNoticeView alloc] initWithView:[self view] title:@"Error reloading Feed"];
            
            [notice show];
        }
        
        if (![[self progressHUD] isHidden]) {
            [[self progressHUD] hide:YES];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"enable_cell" object:nil];
    }];
}

-(void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text
{
    [self setStringToPost:text];
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
    NSString *contentText = [self theFeed][[indexPath row]][@"content"];
    NSString *nameText = [self theFeed][[indexPath row]][@"name"];
    
    CGSize constraint;
    
    if ([self theFeed][[indexPath row]][@"image_url"] && [self theFeed][[indexPath row]][@"image_url"] != [NSNull null]) {
        if ([self theFeed][[indexPath row]][@"repost_user_id"] && [self theFeed][[indexPath row]][@"repost_user_id"] != [NSNull null]) {
            constraint = CGSizeMake(165 - (7.5 * 2), 20000);
        }
        else {
            constraint = CGSizeMake(185 - (7.5 * 2), 20000);
        }
    }
    else {
        constraint = CGSizeMake(215 - (7.5 * 2), 20000);
    }
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:12] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize nameSize = [nameText sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height;
    
    if ([self theFeed][[indexPath row]][@"repost_user_id"] && [self theFeed][[indexPath row]][@"repost_user_id"] != [NSNull null]) {
        height = jMAX(contentSize.height + nameSize.height + 10, 85);
    }
    else {
        height = jMAX(contentSize.height + nameSize.height + 10, 75);
    }
    
    return height + (10 * 2);
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
    static NSString *SelfCellIdentifier = @"SelfFeedViewCell";
    static NSString *SelfWithImageCellIdentifier = @"SelfWithImageCellIdentifier";
    static NSString *CellWithImageCellIdentifier = @"CellWithImageCellIdentifier";
    
    id cell = nil;
    
    if ([[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
        if ([self theFeed][[indexPath row]][@"image_url"] && [self theFeed][[indexPath row]][@"image_url"] != [NSNull null]) {
            cell = [tableView dequeueReusableCellWithIdentifier:SelfWithImageCellIdentifier];
            
            if (cell) {
                if ([[kAppDelegate externalImageCache] objectForKey:indexPath]) {
                    [[cell externalImage] setImage:[[kAppDelegate externalImageCache] objectForKey:indexPath] borderWidth:2 shadowDepth:5 controlPointXOffset:20 controlPointYOffset:25];
                }
                else {
                    [[cell externalImage] setImage:nil];
                }
            }
            else if (!cell) {
                cell = [[SelfWithImageCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SelfWithImageCellIdentifier];
                
                [cell setBackgroundView:[[GradientView alloc] init]];
            }
        }
        else {
            cell = [tableView dequeueReusableCellWithIdentifier:SelfCellIdentifier];
            
            if (!cell) {
                cell = [[SelfCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SelfCellIdentifier];
                
                [cell setBackgroundView:[[GradientView alloc] init]];
            }
        }
    }
    else {
        if ([self theFeed][[indexPath row]][@"image_url"] && [self theFeed][[indexPath row]][@"image_url"] != [NSNull null]) {
            cell = [tableView dequeueReusableCellWithIdentifier:CellWithImageCellIdentifier];
            
            if (cell) {
                if ([[kAppDelegate externalImageCache] objectForKey:indexPath]) {
                    [[cell externalImage] setImage:[[kAppDelegate externalImageCache] objectForKey:indexPath] borderWidth:2 shadowDepth:5 controlPointXOffset:20 controlPointYOffset:25];
                }
                else {
                    [[cell externalImage] setImage:nil];
                }
            }
            else if (!cell) {
                cell = [[NormalWithImageCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellWithImageCellIdentifier];
                
                [cell setBackgroundView:[[GradientView alloc] init]];
            }
        }
        else {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            if (!cell) {
                cell = [[NormalCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                
                [cell setBackgroundView:[[GradientView alloc] init]];
            }
        }
    }
    
    if ([self theFeed][[indexPath row]][@"image_url"] && [self theFeed][[indexPath row]][@"image_url"] != [NSNull null]) {
        if (![[cell externalImage] image]) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            
            objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
            
            dispatch_async(queue, ^{
                [[cell externalActivityIndicator] startAnimating];
                
                NSMutableString *tempString = [NSMutableString stringWithString:[self theFeed][[indexPath row]][@"image_url"]];
                
                [tempString insertString:@"s" atIndex:24];
                
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
                
                if (image) {
                    [[kAppDelegate externalImageCache] setObject:image forKey:indexPath];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[cell externalImage] setImage:image borderWidth:2 shadowDepth:5 controlPointXOffset:20 controlPointYOffset:25];
                });
            });
        }
    }
    
    [[cell contentText] setFontName:@"Helvetica"];
    [[cell contentText] setFontSize:14];
    
    if ([self theFeed][[indexPath row]][@"content"]) {
        [[cell contentText] setText:[self theFeed][[indexPath row]][@"content"]];
    }
    else {
        [[cell contentText] setText:@"Loading..."];
    }
    
    if ([self theFeed][[indexPath row]][@"name"] && [self theFeed][[indexPath row]][@"name"] != [NSNull null]) {
        [[cell nameLabel] setText:[self theFeed][[indexPath row]][@"name"]];
    }
    else {
        if ([self nameDict][[self theFeed][[indexPath row]][@"user_id"]]) {
            [[cell nameLabel] setText:[NSString stringWithFormat:@"%@", [self nameDict][[self theFeed][[indexPath row]][@"user_id"]]]];
        }
        else {
            [[cell nameLabel] setText:@"Loading..."];
        }
    }
    
    if ([self theFeed][[indexPath row]][@"username"] && [self theFeed][[indexPath row]][@"username"] != [NSNull null]) {
        [[cell usernameLabel] setText:[self theFeed][[indexPath row]][@"username"]];
    }
    
    if ([self theFeed][[indexPath row]][@"repost_user_id"] && [self theFeed][[indexPath row]][@"repost_user_id"] != [NSNull null]) {
        CGSize contentSize;
        
        if ([self theFeed][[indexPath row]][@"image_url"] && [self theFeed][[indexPath row]][@"image_url"] != [NSNull null]) {
            contentSize = [[self theFeed][[indexPath row]][@"content"] sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]
                                                                  constrainedToSize:CGSizeMake(185 - (7.5 * 2), 20000)
                                                                      lineBreakMode:NSLineBreakByWordWrapping];
        }
        else {
            contentSize = [[self theFeed][[indexPath row]][@"content"] sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]
                                                                  constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                      lineBreakMode:NSLineBreakByWordWrapping];
        }
        CGSize nameSize = [[self theFeed][[indexPath row]][@"name"] sizeWithFont:[UIFont systemFontOfSize:12]
                                                               constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                   lineBreakMode:NSLineBreakByWordWrapping];
        
        CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 75);
        
        if ([self theFeed][[indexPath row]][@"image_url"] && [self theFeed][[indexPath row]][@"image_url"] != [NSNull null]) {
            if ([[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
                [[cell repostedNameLabel] setFrame:CGRectMake(12, height + 11, 228, 20)];
            }
            else {
                [[cell repostedNameLabel] setFrame:CGRectMake(86, height + 11, 228, 20)];
            }
        }
        else {
            if ([[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
                [[cell repostedNameLabel] setFrame:CGRectMake(12, height, 228, 20)];
            }
            else {
                [[cell repostedNameLabel] setFrame:CGRectMake(86, height, 228, 20)];
            }
        }
        [[cell repostedNameLabel] setText:[NSString stringWithFormat:@"Reposted by %@", [self theFeed][[indexPath row]][@"repost_name"]]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self theFeed][[indexPath row]][@"created_at"] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][@"email"]]]]];
    
    [[cell activityIndicator] startAnimating];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][@"email"]]]] error:nil];
    
    if (image) {
        [[cell activityIndicator] stopAnimating];
        
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if ([NSDate daysBetween:[NSDate date] and:attributes[NSFileCreationDate]] > 1) {
            dispatch_async(queue, ^{
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self theFeed][[indexPath row]][@"email"]]]];
                
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
                    
                    [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][@"email"]]];
                });
            });
        }
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self theFeed][[indexPath row]][@"email"]]]];
            
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
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][@"email"]]];
            });
        });
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == ([[self theFeed] count] - 1)) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
        
        NSString *requestString = [NSString stringWithFormat:@"{\"first\" : \"%i\", \"last\" : \"%i\"}", [[self theFeed] count], [[self theFeed] count] + 20];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [self initializeActivityIndicator];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                NSMutableArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
                
                NSInteger oldTableViewCount = [[self theFeed] count];
                
                [[self theFeed] addObjectsFromArray:tempArray];
                
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"enable_cell" object:nil];
        }];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

-(void)doubleTap:(NSNotification *)aNotification
{
    if ([[self tabBarController] selectedIndex] == 0) {
        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
        
        [self setTempIndexPath:indexPathOfTappedRow];
        
        BlockActionSheet *cellActionSheet = [[BlockActionSheet alloc] initWithTitle:nil];
        
        [cellActionSheet addButtonWithTitle:@"Reply" block:^{
            [self performSegueWithIdentifier:@"ShowReplyView" sender:self];
            
        }];
        
        [cellActionSheet addButtonWithTitle:@"Repost" block:^{
            [ShareObject repost:indexPathOfTappedRow fromArray:[self theFeed] withViewController:self];
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
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
            [cellActionSheet addButtonWithTitle:@"Share to Facebook" block:^{
                NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
                
                [ShareObject shareToFacebook:[[tempCell contentText] text] withViewController:self];
            }];
        }
        
        [cellActionSheet addButtonWithTitle:@"Share via Mail" block:^{
            NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
            
            [ShareObject sharePostViaMail:tempCell withViewController:self];
        }];
        
        if ([[NSString stringWithFormat:@"%@", [self theFeed][[indexPathOfTappedRow row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
            [cellActionSheet setDestructiveButtonWithTitle:@"Delete Post" block:^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                
                NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
                
                [tempCell disableCell];
                
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][@"id"]]];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
                
                [request setHTTPMethod:@"DELETE"];
                [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
                [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
                
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    [[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow] setSelected:NO animated:YES];
                    
                    [self setCurrentChangeType:DELETE_POST];
                    
                    [self refreshTableInformation:indexPathOfTappedRow from:0 to:[[self theFeed] count] removeSplash:NO];
                    
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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
    if ([[segue identifier] isEqualToString:@"ShowUser"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ShowUserViewController *viewController = (ShowUserViewController *)[navigationController topViewController];
        
        [viewController setUserDict:_tempDict];
    }
    else if ([[segue identifier] isEqualToString:@"ShowPostView"]) {
        if ([self tempImage]) {
            UINavigationController *navigationController = [segue destinationViewController];
            PostViewController *viewController = (PostViewController *)[navigationController topViewController];
            
            [viewController setImageFromExternalSource:[self tempImage]];
        }
        
        [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:@"ShowReplyView"]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [self theFeed][[[self tempIndexPath] row]][@"username"]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:@"ShowRepostView"]) {
        UITableViewCell *tempCell = [[self tableView] cellForRowAtIndexPath:[self tempIndexPath]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setRepostString:[NSString stringWithFormat:@"%@", [[tempCell textLabel] text]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
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
    
    [self presentModalViewController:webViewController animated:YES];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultFailed) {
        BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:@"There was an error sending your email"];
        
        [errorAlert setCancelButtonWithTitle:@"OK" block:nil];
        
        [errorAlert show];
    }
    [controller dismissModalViewControllerAnimated: YES];
}

-(void)refreshControlRefresh:(id)sender
{
    [self initializeActivityIndicator];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"first\" : \"%i\", \"last\" : \"%i\"}", 0, [[self theFeed] count] - 1];
    
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
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
            [[self refreshControl] endRefreshing];
        }
        else {
            [_oldRefreshControl endRefreshing];
        }
        
        [[self activityIndicator] stopAnimating];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"enable_cell" object:nil];
    }];
}

@end
