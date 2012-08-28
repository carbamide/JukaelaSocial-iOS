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

@implementation ShowUserViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];
    
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[[self navigationController] viewControllers] count] <= 1) {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf:)]];
    }
    
    [[self navigationItem] setTitle:@"Show User"];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    [self setFollowers:nil];
    [self setFollowing:nil];
    [self setPosts:nil];
    [self setImFollowing:nil];
    [self setupToolbar];
    
    [[self navigationController] setToolbarHidden:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self changeToActivityIndicator];
        [self getFollowers];
        [self getFollowing];
        [self getPosts];
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
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(followActionSheet:)];
    
    [self setToolbarItems:@[flexSpace, actionItem]];
}

-(void)followActionSheet:(id)sender
{
    BOOL following = NO;
    
    BlockActionSheet *followOrUnfollow = [[BlockActionSheet alloc] initWithTitle:nil];
    
    NSNumber *unfollowID = nil;
    
    NSString *followOrUnfollowString = @"Now following ";
    
    for (NSDictionary *dict in [self imFollowing]) {
        if ([dict[@"id"] isEqualToNumber:[self userDict][@"id"]]) {
            NSLog(@"Already following");
            
            followOrUnfollowString = @"Unfollowed ";
            following = YES;
        }
    }
    
    for (NSDictionary *dict in [self relationships]) {
        if ([dict[@"followed_id"] isEqualToNumber:[self userDict][@"id"]]) {
            unfollowID = dict[@"id"];
        }
    }
    if (following == YES) {
        [followOrUnfollow setDestructiveButtonWithTitle:@"Unfollow" block:^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/relationships/%@.json", kSocialURL, unfollowID]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
            
            [request setHTTPMethod:@"DELETE"];
            [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
            [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
            
            NSString *requestString = [NSString stringWithFormat:@"{\"commit\" : \"Unfollow\", \"id\" : \"%@\"}", [self userDict][@"id"]];
            
            NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
            
            [request setHTTPBody:requestData];
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:[NSString stringWithFormat:@"%@%@", followOrUnfollowString, [self userDict][@"name"]]];
                
                [successNotice show];
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            }];
            
        }];
    }
    else {
        [followOrUnfollow addButtonWithTitle:@"Follow" block:^{
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
            
            NSString *requestString = [NSString stringWithFormat:@"{\"relationship\" : {\"followed_id\" : \"%@\"}, \"commit\" : \"Follow\"}", [self userDict][@"id"]];
            
            NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
            
            NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (data) {
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    
                    WBSuccessNoticeView *successNotice = [WBSuccessNoticeView successNoticeInView:[self view] title:[NSString stringWithFormat:@"Now following %@", [self userDict][@"name"]]];
                    
                    [successNotice show];
                    
                    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                    
                    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(followActionSheet:)];
                    
                    [self setToolbarItems:@[flexSpace, actionItem]];
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
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self changeToActivityIndicator];
        
        [self setImFollowing:nil];
        [self setRelationships:nil];
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
        return 100;
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
            [[cell textLabel] setText:[self userDict][@"name"]];
            [[cell detailTextLabel] setTextAlignment:NSTextAlignmentRight];
            
            if ([self userDict][@"username"] && [self userDict][@"username"] != [NSNull null]) {
                [[cell detailTextLabel] setText:[self userDict][@"username"]];
            }
            else {
                [[cell detailTextLabel] setText:@"No username"];
            }
            
            UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userDict][@"id"]]]]];
            
            if (image) {
                [[cell imageView] setImage:image];
            }
            else {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
                
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userDict][@"email"]]]];
                    
#if (TARGET_IPHONE_SIMULATOR)
                    image = [JEImages normalize:image];
#endif
                    UIImage *resizedImage = [image thumbnailImage:55 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[cell imageView] setImage:resizedImage];
                        [self saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self userDict][@"id"]]];
                    });
                });
            }
        }
            break;
        case 1: {
            [cell prepareForTableView:tableView indexPath:indexPath];
            
            [[cell detailTextLabel] setNumberOfLines:5];
            
            if ([self userDict][@"profile"] && [self userDict][@"profile"] != [NSNull null] ) {
                [[cell detailTextLabel] setText:[self userDict][@"profile"]];
            }
            else {
                [[cell detailTextLabel] setText:@"No user profile"];
            }
            
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
            
            [segmentedCell setText:[NSString stringWithFormat:@"%i", [[self following] count]] atIndex:0];
            [segmentedCell setDetailText:@"Following" atIndex:0];
            
            [segmentedCell setText:[NSString stringWithFormat:@"%i", [[self followers] count]] atIndex:1];
            [segmentedCell setDetailText:@"Followers" atIndex:1];
            
            [segmentedCell setText:[NSString stringWithFormat:@"%i", [[self posts] count]] atIndex:2];
            [segmentedCell setDetailText:@"Posts" atIndex:2];
            
            [segmentedCell setActionBlock:^(NSIndexPath *indexPath, int selectedIndex) {
                if (selectedIndex == 0) {
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self performSegueWithIdentifier:@"ShowFollowing" sender:nil];
                }
                else if (selectedIndex == 1) {
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self performSegueWithIdentifier:@"ShowFollowers" sender:nil];
                }
                else if (selectedIndex == 2) {
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self performSegueWithIdentifier:@"ShowUserPosts" sender:nil];
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
        
        [viewController setUsersArray:[self following]];
        [viewController setTitle:@"Following"];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserPosts"]) {
        UsersPostsViewController *viewController = [segue destinationViewController];
        
        [viewController setUserID:[self userDict][@"id"]];
        [viewController setUserPostArray:[self posts]];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)saveImage:(UIImage *)image withFileName:(NSString *)emailAddress
{
    if (image != nil)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths[0];
        NSString* path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithString:[NSString stringWithFormat:@"%@.png", emailAddress]]];
        NSData* data = UIImagePNGRepresentation(image);
        [data writeToFile:path atomically:YES];
    }
}

-(NSString *)documentsPath
{
    NSArray *tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = tempArray[0];
    
    return documentsDirectory;
}

-(void)getPosts
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userDict][@"id"]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setPosts:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's posts.  Please logout and log back in."];
        }
        
    }];
}

-(void)getFollowing
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/following.json", kSocialURL, [self userDict][@"id"]]];
    
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
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/followers.json", kSocialURL, [self userDict][@"id"]]];
    
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
