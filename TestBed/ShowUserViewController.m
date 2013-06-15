//
//  ShowUserViewController
//  Jukaela Social
//
//  Created by Josh Barrow on 07/19/2012.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "FollowerViewController.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "ShowUserViewController.h"
#import "UsersPostsViewController.h"
#import "WBErrorNoticeView.h"
#import "WBSuccessNoticeView.h"
#import "WBStickyNoticeView.h"

@interface ShowUserViewController ()
@property (strong, nonatomic) NSNumber *followerCount;
@property (strong, nonatomic) NSNumber *followingCount;
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
    
    [[self view] snapshot];
    
    [[self navigationController] setToolbarHidden:NO animated:YES];
    
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf:)]];
    
    [[self navigationItem] setTitle:@"Show User"];
    
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
        [self getNumberOfPosts];
        [self getNumberOfFollowers];
        [self getNumberOfFollowing];
        [self getFollowers];
        [self getFollowing];
        [self getimFollowing];
    });
}

-(void)setupToolbar
{
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
    RIButtonItem *followOrUnfollowButton = nil;
    
    BOOL following = NO;
    
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
        followOrUnfollowButton = [RIButtonItem itemWithLabel:@"Unfollow" action:^{
            [self setImFollowing:nil];
            [self setRelationships:nil];
            
            [self changeToActivityIndicator];
            
            [self performSelector:@selector(followingAndRelationshipsDispatch) withObject:nil afterDelay:0];
            
            [[ActivityManager sharedManager] incrementActivityCount];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/relationships/%@.json", kSocialURL, unfollowID]];
            
            NSLog(@"%@", [url absoluteString]);
            
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
                
                [[ActivityManager sharedManager] decrementActivityCount];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
            }];
        }];
    }
    else {
        followOrUnfollowButton = [RIButtonItem itemWithLabel:@"Follow" action:^{
            [self setImFollowing:nil];
            [self setRelationships:nil];
            
            [self changeToActivityIndicator];
            
            [self performSelector:@selector(followingAndRelationshipsDispatch) withObject:nil afterDelay:0];
            
            [[ActivityManager sharedManager] incrementActivityCount];
            
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
                    [[ActivityManager sharedManager] decrementActivityCount];
                    
                    WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:[NSString stringWithFormat:@"Now following %@", [self userDict][kName]]];
                    
                    [successNotice show];
                    
                    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                    
                    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(followActionSheet:)];
                    
                    [self setToolbarItems:@[flexSpace, actionItem]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
                }
                else {
                    [[ActivityManager sharedManager] decrementActivityCount];
                    
                    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                    
                    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(followActionSheet:)];
                    
                    [self setToolbarItems:@[flexSpace, actionItem]];
                }
            }];
        }];
    }
    
    UIActionSheet *followOrUnfollow = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] destructiveButtonItem:following ? followOrUnfollowButton : nil otherButtonItems:following ? nil : followOrUnfollowButton, nil];
    
    [followOrUnfollow showFromToolbar:[[self navigationController] toolbar]];
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
    
    [activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    
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
        NSString *contentText = [self userDict][@"profile"] && [self userDict][@"profile"] != [NSNull null] ? [self userDict][@"profile"] : @"This user hasn't set a profile!";
        
        CGSize constraint = CGSizeMake(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 750 : 300, 20000);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGSize contentSize = [contentText sizeWithFont:[UIFont preferredFontForTextStyle:UIFontDescriptorTextStyleBody] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
        
        return contentSize.height + 20;
    }
    else {
        return 55;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.section) {
        case 0: {
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            [[cell textLabel] setTextAlignment:NSTextAlignmentRight];
            [[cell textLabel] setText:[self userDict][kName]];
            [[cell detailTextLabel] setTextAlignment:NSTextAlignmentRight];
            
            [[cell textLabel] setFont:[UIFont preferredFontForTextStyle:UIFontDescriptorTextStyleHeadline1]];
            [[cell detailTextLabel] setFont:[UIFont preferredFontForTextStyle:UIFontDescriptorTextStyleHeadline2]];
            
            if ([self userDict][kUsername] && [self userDict][kUsername] != [NSNull null]) {
                [[cell detailTextLabel] setText:[NSString stringWithFormat:@"@%@", [self userDict][kUsername]]];
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
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            [[cell detailTextLabel] setNumberOfLines:6];
            
            [[cell detailTextLabel] setFont:[UIFont preferredFontForTextStyle:UIFontDescriptorTextStyleBody]];
            
            if ([self userDict][@"profile"] && [self userDict][@"profile"] != [NSNull null] ) {
                [[cell detailTextLabel] setText:[self userDict][@"profile"]];
            }
            else {
                [[cell detailTextLabel] setText:@"This user hasn't set a profile!"];
            }
            
            [[cell detailTextLabel] setTextColor:[UIColor blackColor]];
            
            return cell;
        }
        case 2: {
            UIButton *tempFollowing = [UIButton buttonWithType:UIButtonTypeSystem];
            
            [tempFollowing setFrame:CGRectMake(0, 0, 106, 55)];
            [tempFollowing addTarget:self action:@selector(showFollowing:) forControlEvents:UIControlEventTouchUpInside];
            
            if ([[self followingCount] intValue] > 0) {
                [tempFollowing setTitle:[NSString stringWithFormat:@"Following %@", [self followingCount]] forState:UIControlStateNormal];
            }
            else {
                [tempFollowing setTitle:@"Following 0" forState:UIControlStateNormal];
            }
            
            [cell addSubview:tempFollowing];
            
            UIButton *tempFollowers = [UIButton buttonWithType:UIButtonTypeSystem];
            
            [tempFollowers setFrame:CGRectMake(106, 0, 106, 55)];
            [tempFollowers addTarget:self action:@selector(showFollowers:) forControlEvents:UIControlEventTouchUpInside];
            
            if ([[self followerCount] intValue] > 0) {
                [tempFollowers setTitle:[NSString stringWithFormat:@"%@ Followers", [self followerCount]] forState:UIControlStateNormal];
            }
            else {
                [tempFollowers setTitle:@"Following 0" forState:UIControlStateNormal];
            }
            
            [cell addSubview:tempFollowers];
            
            UIButton *tempPosts = [UIButton buttonWithType:UIButtonTypeSystem];
            
            [tempPosts setFrame:CGRectMake(212, 0, 106, 55)];
            [tempPosts addTarget:self action:@selector(getPosts) forControlEvents:UIControlEventTouchUpInside];
            
            if ([[self followerCount] intValue] > 0) {
                [tempPosts setTitle:[NSString stringWithFormat:@"%@ Posts", [self followerCount]] forState:UIControlStateNormal];
            }
            else {
                [tempPosts setTitle:@"0 Posts" forState:UIControlStateNormal];
            }
            
            [cell addSubview:tempPosts];
        }

            break;
        default:
            break;
    }
    return cell;
}

-(void)showFollowing:(id)sender
{
    [self performSegueWithIdentifier:kShowFollowing sender:nil];
}

-(void)showFollowers:(id)sender
{
    [self performSegueWithIdentifier:kShowFollowers sender:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
   if ([[segue identifier] isEqualToString:@"ShowFollowers"]) {
       FollowerViewController *viewController = [segue destinationViewController];
   
   
       [viewController setUsersArray:[self followers]];
       [viewController setTitle:@"Followers"];
   }
   else if ([[segue identifier] isEqualToString:@"ShowFollowing"]) {
       FollowerViewController *viewController = [segue destinationViewController];
   
       [viewController setUsersArray:[self following][@"user"]];
   
       [viewController setTitle:@"Following"];
   }
   else
    if ([[segue identifier] isEqualToString:@"ShowUserPosts"]) {
        UsersPostsViewController *viewController = [segue destinationViewController];
        
        [viewController setUserID:[self userDict][kID]];
        [viewController setUserPostArray:[[self posts] mutableCopy]];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)getPosts
{
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userDict][kID]]];
    
    NSString *requestString = [RequestFactory feedRequestFrom:0 to:20];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setPosts:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
            
            [[ActivityManager sharedManager] decrementActivityCount];
            
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
            [self setPostCount:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"count"]];
            
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
        }
        else {
            NSLog(@"Error retrieving posts count");
        }
    }];
}

-(void)getNumberOfFollowers
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/number_of_followers", kSocialURL, [self userDict][kID]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setFollowerCount:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"count"]];
            
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
        }
        else {
            NSLog(@"Error retrieving posts count");
        }
    }];
}

-(void)getNumberOfFollowing
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/number_of_following", kSocialURL, [self userDict][kID]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setFollowingCount:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"count"]];
            
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
        }
        else {
            NSLog(@"Error retrieving posts count");
        }
    }];
}

-(void)getFollowing
{
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/following.json", kSocialURL, [self userDict][kID]]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [self setFollowing:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
    }];
}

-(void)getimFollowing
{
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/following.json", kSocialURL, [kAppDelegate userID]]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [self setImFollowing:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"user"]];
            [self setRelationships:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"relationships"]];
            
            [self setupToolbar];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
    }];
}

-(void)getFollowers
{
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/followers.json", kSocialURL, [self userDict][kID]]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [self setFollowers:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
    }];
}

@end
