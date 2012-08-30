//
//  FeedViewController.m
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//
#import <objc/runtime.h>
#import "AppDelegate.h"
#import "ClearLabelsCellView.h"
#import "FeedViewController.h"
#import "GradientView.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "NSData+reallyMapped.h"
#import "NSDate+RailsDateParser.h"
#import "NSString+BackslashEscape.h"
#import "PostViewController.h"
#import "ShowUserViewController.h"
#import "SORelativeDateTransformer.h"
#import "SVModalWebViewController.h"
#import "WBErrorNoticeView.h"
#import "WBSuccessNoticeView.h"
#import "WBStickyNoticeView.h"

@interface FeedViewController ()
@property (strong, nonatomic) NSString *stringToPost;
@property (strong, nonatomic) ODRefreshControl *oldRefreshControl;
@property (nonatomic) ChangeType currentChangeType;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSNotificationCenter *refreshTableNotificationCenter;
@property (strong, nonatomic) NSNotificationCenter *changeTypeNotificationCenter;
@property (strong, nonatomic) NSNotificationCenter *tweetSuccessfullNotificationCenter;
@property (strong, nonatomic) NSNotificationCenter *facebookSuccessfullNotificationCenter;
@property (strong, nonatomic) NSNotificationCenter *jukaelaSuccessfullNotificationCenter;
@property (nonatomic) BOOL fbSuccess;
@property (nonatomic) BOOL twitterSuccess;
@property (nonatomic) BOOL jukaelaSuccess;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;

-(void)refreshTableInformation:(NSIndexPath *)indexPath;

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

    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"double_tap" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"send_to_user" object:nil];

    [super viewDidDisappear:animated];
}

-(void)viewDidLoad
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        
        [refreshControl setTintColor:[UIColor blackColor]];
        
        [refreshControl addTarget:self action:@selector(refreshTableInformation:) forControlEvents:UIControlEventValueChanged];
        
        [self setRefreshControl:refreshControl];
    }
    else {
        _oldRefreshControl = [[ODRefreshControl alloc] initInScrollView:[self tableView]];
        
        [_oldRefreshControl setTintColor:[UIColor blackColor]];
        
        [_oldRefreshControl addTarget:self action:@selector(refreshTableInformation:) forControlEvents:UIControlEventValueChanged];
    }
    
    [self setupNotifications];
    
    if (![self theFeed]) {
        [self refreshTableInformation:nil];
    }
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composePost:)];
    
    [[self navigationItem] setRightBarButtonItem:composeButton];
    
    [[self navigationItem] setHidesBackButton:YES];
    
    [self setCurrentChangeType:-1];
    
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [super viewDidLoad];
}

-(void)setupNotifications
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [self setChangeTypeNotificationCenter:[defaultCenter addObserverForName:@"set_change_type"
                                                                     object:nil
                                                                      queue:mainQueue usingBlock:^(NSNotification *number) {
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
                                                                      }]];
    
    [self setChangeTypeNotificationCenter:[defaultCenter addObserverForName:@"refresh_your_tables"
                                                                     object:nil
                                                                      queue:mainQueue usingBlock:^(NSNotification *aNotification) {
                                                                          [self refreshTableInformation:nil];
                                                                      }]];
    
    [self setTweetSuccessfullNotificationCenter:[defaultCenter addObserverForName:@"tweet_successful"
                                                                           object:nil
                                                                            queue:mainQueue usingBlock:^(NSNotification *aNotification) {
                                                                                [self setTwitterSuccess:YES];
                                                                                
                                                                                [self checkForFBAndTwitterSucess];
                                                                            }]];
    
    [self setFacebookSuccessfullNotificationCenter:[defaultCenter addObserverForName:@"facebook_successful"
                                                                              object:nil
                                                                               queue:mainQueue usingBlock:^(NSNotification *aNotification) {
                                                                                   [self setFbSuccess:YES];
                                                                                   
                                                                                   [self checkForFBAndTwitterSucess];
                                                                               }]];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"facebook_or_twitter_sending" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        if (![self activityIndicator]) {
            [self setActivityIndicator:[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)]];
        }
        
        [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:[self activityIndicator]]];
        
        if (![[self activityIndicator] isAnimating]) {
            [[self activityIndicator] startAnimating];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"stop_animating" object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        if ([[self activityIndicator] isAnimating]) {
            [[self activityIndicator] stopAnimating];
        }
    }];
}

-(void)switchToSelectedUser:(NSNotification *)aNotification
{
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:[self view]];
    [progressHUD setMode:MBProgressHUDModeIndeterminate];
    [progressHUD setLabelText:@"Loading User..."];
    [progressHUD setDelegate:self];
    
    [[self view] addSubview:progressHUD];
    
    [progressHUD show:YES];
    
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[indexPathOfTappedRow row]][@"user_id"]]];
    
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
        
        [progressHUD hide:YES];
        
        [self performSegueWithIdentifier:@"ShowUser" sender:nil];
    }];
}

-(void)checkForFBAndTwitterSucess
{
    if (([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) && ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == NO)) {
        if ([self twitterSuccess]) {
            WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Tweet Tweeted"];
            
            [successNotice show];
            
            [self setTwitterSuccess:NO];
            
            [[self activityIndicator] startAnimating];
        }
    }
    else if (([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) && ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == NO)) {
        if ([self fbSuccess]) {
            WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Facebook Post Posted"];
            
            [successNotice show];
            
            [self setFbSuccess:NO];
            
            [[self activityIndicator] startAnimating];
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
        if ([self twitterSuccess] && [self fbSuccess]) {
            WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:@"Twitter and FB - Good to Go!"];
            
            [successNotice show];
            
            [self setTwitterSuccess:NO];
            [self setFbSuccess:NO];
            
            [[self activityIndicator] startAnimating];
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

-(void)refreshTableInformation:(NSIndexPath *)indexPath
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            int oldNumberOfPosts = [[self theFeed] count];
                        
            [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            int newNumberOfPosts = [[self theFeed] count];
            
            if ([self currentChangeType] == INSERT_POST) {
                [[self tableView] beginUpdates];
                [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                [[self tableView] endUpdates];
            }
            else if ([self currentChangeType] == DELETE_POST) {
                [[self tableView] beginUpdates];
                [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [[self tableView] endUpdates];
            }
            else {
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
            [Helpers errorAndLogout:self withMessage:@"There was an error reloading your feed.  Please logout and log back in."];
        }
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
    
    CGSize constraint = CGSizeMake(215 - (7.5 * 2), 20000);
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:12] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize nameSize = [nameText sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 75);
    
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
    static NSString *CellIdentifier = @"Cell";
    
    ClearLabelsCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[ClearLabelsCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        [cell setBackgroundView:[[GradientView alloc] init]];
    }
    
    [[cell contentText] setFont:[UIFont fontWithName:@"Helvetica" size:14]];
        
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
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self theFeed][[indexPath row]][@"created_at"] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self theFeed][[indexPath row]][@"email"]]]]];
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
        
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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
            [self performSegueWithIdentifier:@"ShowRepostView" sender:self];
            
        }];
        
        if ([[NSString stringWithFormat:@"%@", [self theFeed][[indexPathOfTappedRow row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
            [cellActionSheet setDestructiveButtonWithTitle:@"Delete Post" block:^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                
                NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
                
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, [self theFeed][[indexPath row]][@"id"]]];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
                
                [request setHTTPMethod:@"DELETE"];
                [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
                [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
                
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
                    
                    [self setCurrentChangeType:DELETE_POST];
                    
                    [self refreshTableInformation:indexPathOfTappedRow];
                    
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

-(NSString *)documentsPath
{
    NSArray *tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = tempArray[0];
    
    return documentsDirectory;
}

-(void)dealloc
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver:[self refreshTableNotificationCenter]];
    [center removeObserver:[self changeTypeNotificationCenter]];
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

@end
