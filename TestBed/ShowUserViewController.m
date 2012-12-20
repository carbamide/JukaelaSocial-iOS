//
//  ShowUserViewController
//  Jukaela Social
//
//  Created by Josh Barrow on 07/19/2012.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import "FollowerViewController.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "ShowUserViewController.h"
#import "UsersPostsViewController.h"
#import "WBErrorNoticeView.h"
#import "WBSuccessNoticeView.h"
#import "WBStickyNoticeView.h"

@interface ShowUserViewController ()
@property (strong, nonatomic) NSNumber *postCount;
@end

@implementation ShowUserViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];
    
    [[self navigationController] setToolbarHidden:NO animated:YES];
    
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[[self navigationController] viewControllers] count] <= 1) {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf:)]];
    }
    
    [[self navigationItem] setTitle:@"Show User"];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    [self setFollowers:nil];
    [self setFollowing:nil];
    [self setPosts:nil];
    [self setImFollowing:nil];
    [self setupToolbar];
    
    [[self navigationController] setToolbarHidden:NO];
    
    [self changeToActivityIndicator];
    
    [self performSelector:@selector(setupArraysDispatch) withObject:nil afterDelay:0];
}

-(void)setupArraysDispatch
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self getFollowers];
        [self getFollowing];
        [self getNumberOfPosts];
        [self getimFollowing];
    });
}

-(void)setupToolbar
{
    PrettyToolbar *toolbar = (PrettyToolbar *)self.navigationController.toolbar;
    
    [toolbar setTopLineColor:[UIColor colorWithHex:0xafafaf]];
    [toolbar setGradientStartColor:[UIColor colorWithHex:0x969696]];
    [toolbar setGradientEndColor:[UIColor colorWithHex:0x3e3e3e]];
    [toolbar setBottomLineColor:[UIColor colorWithHex:0x303030]];
    [toolbar setTintColor:[toolbar gradientEndColor]];
    
    if ([[kAppDelegate userID] isEqualToString:[NSString stringWithFormat:@"%@", [self userDict][kID]]]) {
        [self setToolbarItems:nil];
        
        return;
    }
    else {
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(followActionSheet:)];
        
        [self setToolbarItems:@[flexSpace, actionItem]];
    }
}

-(void)followActionSheet:(id)sender
{
    BOOL following = NO;
    
    BlockActionSheet *followOrUnfollow = [[BlockActionSheet alloc] initWithTitle:nil];
    
    NSNumber *unfollowID = nil;
    
    NSString *followOrUnfollowString = @"Now following ";
    
    for (NSDictionary *dict in [self imFollowing]) {
        if ([dict[kID] isEqualToNumber:[self userDict][kID]]) {
            followOrUnfollowString = @"Unfollowed ";
            following = YES;
        }
    }
    
    for (NSDictionary *dict in [self relationships]) {
        if ([dict[@"followed_id"] isEqualToNumber:[self userDict][kID]]) {
            unfollowID = dict[kID];
        }
    }
    if (following == YES) {
        [followOrUnfollow setDestructiveButtonWithTitle:@"Unfollow" block:^{
            [self setImFollowing:nil];
            [self setRelationships:nil];
            
            [self changeToActivityIndicator];
            
            [self performSelector:@selector(followingAndRelationshipsDispatch) withObject:nil afterDelay:0];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/relationships/%@.json", kSocialURL, unfollowID]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
            
            [request setHTTPMethod:@"DELETE"];
            [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
            [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
            
            NSString *requestString = [RequestFactory unfollowRequestWithUserID:[self userDict][kID]];
            
            NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
            
            [request setHTTPBody:requestData];
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:[NSString stringWithFormat:@"%@%@", followOrUnfollowString, [self userDict][kName]]];
                
                [successNotice show];
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
            }];
        }];
    }
    else {
        [followOrUnfollow addButtonWithTitle:@"Follow" block:^{
            [self setImFollowing:nil];
            [self setRelationships:nil];
            
            [self changeToActivityIndicator];
            
            [self performSelector:@selector(followingAndRelationshipsDispatch) withObject:nil afterDelay:0];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
            
            [activityView sizeToFit];
            
            [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin |
                                               UIViewAutoresizingFlexibleRightMargin |
                                               UIViewAutoresizingFlexibleTopMargin |
                                               UIViewAutoresizingFlexibleBottomMargin)];
            [activityView startAnimating];
            
            UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
            
            UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            [self setToolbarItems:@[flexSpace, loadingView]];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/relationships.json", kSocialURL]];
            
            NSString *requestString = [RequestFactory followRequestWithUserID:[self userDict][kID]];
            
            NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
            
            NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (data) {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    
                    WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:[NSString stringWithFormat:@"Now following %@", [self userDict][kName]]];
                    
                    [successNotice show];
                    
                    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                    
                    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(followActionSheet:)];
                    
                    [self setToolbarItems:@[flexSpace, actionItem]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
                }
                else {
                    BlockAlertView *jukaelaSocialPostingError = [[BlockAlertView alloc] initWithTitle:@"Oh No!" message:@"There has been an error following or unfollowing"];
                    
                    [jukaelaSocialPostingError setCancelButtonWithTitle:@"OK" block:nil];
                    
                    [jukaelaSocialPostingError show];
                    
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    
                    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                    
                    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(followActionSheet:)];
                    
                    [self setToolbarItems:@[flexSpace, actionItem]];
                }
            }];
        }];
    }
    
    [followOrUnfollow setCancelButtonWithTitle:@"Cancel" block:nil];
    
    [followOrUnfollow showInView:[self view]];
}

-(void)followingAndRelationshipsDispatch
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self getimFollowing];
    });
}

-(void)changeToActivityIndicator
{
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    
    [activityView sizeToFit];
    
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin)];
    [activityView startAnimating];
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [self setToolbarItems:@[flexSpace, loadingView]];
}

-(void)dismissSelf:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    
    if (section == 1) {
        return 1;
    }
    
    if (section == 2) {
        return 1;
    }
    
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {
        return 100;
    }
    else if ([indexPath section] == 1) {
        return 120;
    }
    else {
        return 55;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *SegmentedCellIdentifier = @"SegmentedCell";
    
    PrettyGridTableViewCell *segmentedCell;
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.section) {
        case 0: {
            [cell prepareForTableView:tableView indexPath:indexPath];
            
            [[cell textLabel] setTextAlignment:NSTextAlignmentRight];
            [[cell textLabel] setText:[self userDict][kName]];
            [[cell detailTextLabel] setTextAlignment:NSTextAlignmentRight];
            
            [[cell textLabel] setFont:[UIFont fontWithName:kFontPreference size:18]];
            [[cell detailTextLabel] setFont:[UIFont fontWithName:kFontPreference size:16]];
            
            if ([self userDict][kUsername] && [self userDict][kUsername] != [NSNull null]) {
                [[cell detailTextLabel] setText:[self userDict][kUsername]];
            }
            else {
                [[cell detailTextLabel] setText:@"No username"];
            }
            
            UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@-large.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userDict][kID]]]]];
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@-large.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userDict][kID]]]] error:nil];
            
            if (image) {
                [[cell imageView] setImage:image];
                [cell setNeedsDisplay];
                
                if (attributes) {
                    if ([NSDate daysBetween:[NSDate date] and:attributes[NSFileCreationDate]] > 1) {
                        dispatch_async(queue, ^{
                            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userDict][kEmail] withSize:65]]];
                            
#if (TARGET_IPHONE_SIMULATOR)
                            image = [JEImages normalize:image];
#endif
                            UIImage *resizedImage = [image thumbnailImage:65 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[cell imageView] setImage:resizedImage];
                                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@-large", [self userDict][kID]]];
                            });
                        });
                    }
                }
            }
            else {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userDict][kEmail] withSize:65]]];
                    
#if (TARGET_IPHONE_SIMULATOR)
                    image = [JEImages normalize:image];
#endif
                    UIImage *resizedImage = [image thumbnailImage:65 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[cell imageView] setImage:resizedImage];
                        
                        [cell setNeedsDisplay];
                        
                        [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@-large", [self userDict][kID]]];
                    });
                });
            }
        }
            break;
        case 1: {
            [cell prepareForTableView:tableView indexPath:indexPath];
            
            [[cell detailTextLabel] setNumberOfLines:5];
            
            [[cell detailTextLabel] setFont:[UIFont fontWithName:kFontPreference size:16]];
            
            if ([self userDict][@"profile"] && [self userDict][@"profile"] != [NSNull null] ) {
                [[cell detailTextLabel] setText:[self userDict][@"profile"]];
            }
            else {
                [[cell detailTextLabel] setText:@"No user profile"];
            }
            
            [[cell detailTextLabel] setTextColor:[UIColor blackColor]];
            
            return cell;
        }
        case 2: {
            segmentedCell = [tableView dequeueReusableCellWithIdentifier:SegmentedCellIdentifier];
            
            if (segmentedCell == nil) {
                segmentedCell = [[PrettySegmentedControlTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SegmentedCellIdentifier];
            }
            
            __weak PrettyGridTableViewCell *tempSegContCell = segmentedCell;
            
            [segmentedCell prepareForTableView:tableView indexPath:indexPath];
            
            [segmentedCell setNumberOfElements:3];
            
            [segmentedCell setText:[NSString stringWithFormat:@"%i", [[self following][@"user"] count]] atIndex:0];
            [segmentedCell setDetailText:@"Following" atIndex:0];
            
            [segmentedCell setText:[NSString stringWithFormat:@"%i", [[self followers] count]] atIndex:1];
            [segmentedCell setDetailText:@"Followers" atIndex:1];
            
            if ([[self postCount] intValue] > 0) {
                [segmentedCell setText:[NSString stringWithFormat:@"%@", [self postCount]] atIndex:2];
            }
            else {
                [segmentedCell setText:@"0" atIndex:2];
            }
            
            [segmentedCell setDetailText:@"Posts" atIndex:2];
            
            [segmentedCell setActionBlock:^(NSIndexPath *indexPath, int selectedIndex) {
                if (selectedIndex == 0) {
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self performSegueWithIdentifier:kShowFollowing sender:nil];
                }
                else if (selectedIndex == 1) {
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self performSegueWithIdentifier:kShowFollowers sender:nil];
                }
                else if (selectedIndex == 2) {
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self getPosts];
                }
            }];
        }
            return segmentedCell;
            break;
        default:
            break;
    }
    
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowFollowers"]) {
        PrettySegmentedControlTableViewCell *tempCell = (PrettySegmentedControlTableViewCell *)[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        [tempCell deselectAnimated:YES];
        
        FollowerViewController *viewController = [segue destinationViewController];
        
        
        [viewController setUsersArray:[self followers]];
        [viewController setTitle:@"Followers"];
    }
    else if ([[segue identifier] isEqualToString:@"ShowFollowing"]) {
        PrettySegmentedControlTableViewCell *tempCell = (PrettySegmentedControlTableViewCell *)[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        [tempCell deselectAnimated:YES];
        
        FollowerViewController *viewController = [segue destinationViewController];
        
        [viewController setUsersArray:[self following][@"user"]];
        
        [viewController setTitle:@"Following"];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserPosts"]) {
        UsersPostsViewController *viewController = [segue destinationViewController];
        
        [viewController setUserID:[self userDict][kID]];
        [viewController setUserPostArray:[self posts]];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)getPosts
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userDict][kID]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setPosts:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self performSegueWithIdentifier:kShowUserPosts sender:nil];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's posts.  Please logout and log back in."];
        }
        
    }];
}

-(void)getNumberOfPosts
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/number_of_posts", kSocialURL, [self userDict][kID]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setPostCount:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil][@"count"]];
            
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            NSLog(@"Error retrieving posts count");
        }
    }];
}

-(void)getFollowing
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/following.json", kSocialURL, [self userDict][kID]]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self setFollowing:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
    }];
}

-(void)getimFollowing
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/following.json", kSocialURL, [kAppDelegate userID]]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self setImFollowing:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil][@"user"]];
            [self setRelationships:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil][@"relationships"]];
            
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [self setupToolbar];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
    }];
}

-(void)getFollowers
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/followers.json", kSocialURL, [self userDict][kID]]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self setFollowers:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
    }];
}

@end
