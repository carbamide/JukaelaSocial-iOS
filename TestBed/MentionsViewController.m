//
//  MentionsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 8/29/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import "NormalCellView.h"
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "MentionsViewController.h"
#import "PostViewController.h"
#import "ShowUserViewController.h"
#import "SORelativeDateTransformer.h"
#import "WBSuccessNoticeView.h"
#import "NormalWithImageCellView.h"
#import "UIImageView+Curled.h"

@interface MentionsViewController ()
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) NSNotificationCenter *refreshTableNotificationCenter;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) YIFullScreenScroll *fullScreenDelegate;

@end

@implementation MentionsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [_fullScreenDelegate layoutTabBarController];

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

- (void)viewDidLoad
{
    _fullScreenDelegate = [[YIFullScreenScroll alloc] initWithViewController:self];
    
    [self refreshTableInformation];
    
    JRefreshControl *refreshControl = [[JRefreshControl alloc] init];
    
    [refreshControl setTintColor:[UIColor blackColor]];
    
    [refreshControl addTarget:self action:@selector(refreshTableInformation) forControlEvents:UIControlEventValueChanged];
    
    [self setRefreshControl:refreshControl];
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composePost:)];
    
    [[self navigationItem] setRightBarButtonItem:composeButton];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [super viewDidLoad];
}

-(void)composePost:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"ShowPostView" sender:self];
}

-(void)setupNotifications
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [defaultCenter addObserverForName:@"refresh_your_tables" object:nil queue:mainQueue usingBlock:^(NSNotification *notification) {
        [self refreshTableInformation];
    }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentText = [self mentions][[indexPath row]][@"content"];
    
    CGSize constraint = CGSizeMake(315, 20000);
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont fontWithName:@"Helvetica-Light" size:17] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    if ([self mentions][[indexPath row]][@"repost_user_id"] && [self mentions][[indexPath row]][@"repost_user_id"] != [NSNull null]) {
        return contentSize.height + 50 + 10 + 20;
    }
    else {
        return contentSize.height + 50 + 10;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self mentions] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FeedViewCell";
    static NSString *CellWithImageCellIdentifier = @"CellWithImageCellIdentifier";
    
    id cell = nil;
    
    if ([self mentions][[indexPath row]][@"image_url"] && [self mentions][[indexPath row]][@"image_url"] != [NSNull null]) {
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
    
    if ([self mentions][[indexPath row]][@"image_url"] && [self mentions][[indexPath row]][@"image_url"] != [NSNull null]) {
        if (![[cell externalImage] image]) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
            
            dispatch_async(queue, ^{
                NSMutableString *tempString = [NSMutableString stringWithString:[self mentions][[indexPath row]][@"image_url"]];
                
                [tempString insertString:@"s" atIndex:24];
                
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[cell externalImage] setImage:image borderWidth:2 shadowDepth:5 controlPointXOffset:20 controlPointYOffset:25];
                });
            });
        }
    }
    
    [[cell contentText] setFontName:@"Helvetica-Light"];
    [[cell contentText] setFontSize:17];
    
    if ([self mentions][[indexPath row]][@"content"]) {
        [[cell contentText] setText:[self mentions][[indexPath row]][@"content"]];
    }
    else {
        [[cell contentText] setText:@"Loading..."];
    }
    
    if ([self mentions][[indexPath row]][@"sender_name"] && [self mentions][[indexPath row]][@"sender_name"] != [NSNull null]) {
        [[cell nameLabel] setText:[self mentions][[indexPath row]][@"sender_name"]];
    }
    
    if ([self mentions][[indexPath row]][@"sender_username"] && [self mentions][[indexPath row]][@"sender_username"] != [NSNull null]) {
        [[cell usernameLabel] setText:[self mentions][[indexPath row]][@"sender_username"]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self mentions][[indexPath row]][@"created_at"] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self mentions][[indexPath row]][@"sender_user_id"]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self mentions][[indexPath row]][@"sender_user_id"]]]] error:nil];
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetween:[NSDate date] and:attributes[NSFileCreationDate]] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self mentions][[indexPath row]][@"sender_email"] withSize:40]]];
                    
#if (TARGET_IPHONE_SIMULATOR)
                    image = [JEImages normalize:image];
#endif
                    UIImage *resizedImage = [image thumbnailImage:40 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
                        
                        if ([indexPath isEqual:cellIndexPath]) {
                            [[cell imageView] setImage:resizedImage];
                            [cell setNeedsDisplay];
                        }
                        
                        [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self mentions][[indexPath row]][@"sender_user_id"]]];
                    });
                });
            }
        }
    }
    else {
		dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self mentions][[indexPath row]][@"sender_email"] withSize:40]]];
			
#if (TARGET_IPHONE_SIMULATOR)
            image = [JEImages normalize:image];
#endif
            UIImage *resizedImage = [image thumbnailImage:40 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
				
				if ([indexPath isEqual:cellIndexPath]) {
					[[cell imageView] setImage:resizedImage];
                    [cell setNeedsDisplay];
				}
				
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self mentions][[indexPath row]][@"sender_user_id"]]];
			});
		});
	}
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)doubleTap:(NSNotification *)aNotification
{
    [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];

    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    [self setTempIndexPath:indexPathOfTappedRow];
    
    BlockActionSheet *cellActionSheet = [[BlockActionSheet alloc] initWithTitle:nil];
    
    [cellActionSheet addButtonWithTitle:@"Reply" block:^{
        [self performSegueWithIdentifier:@"ShowReplyView" sender:self];
        
    }];
    
    if ([[NSString stringWithFormat:@"%@", [self mentions][[indexPathOfTappedRow row]][@"sender_user_id"]] isEqualToString:[kAppDelegate userID]]) {
        [cellActionSheet setDestructiveButtonWithTitle:@"Delete Post" block:^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
            
            [tempCell disableCell];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/mentions/%@.json", kSocialURL, [self mentions][[indexPathOfTappedRow row]][@"id"]]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
            
            [request setHTTPMethod:@"DELETE"];
            [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
            [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
                
                [self refreshTableInformation];
                
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowReplyView"]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [self mentions][[[self tempIndexPath] row]][@"sender_username"]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUser"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ShowUserViewController *viewController = (ShowUserViewController *)[navigationController topViewController];
        
        [viewController setUserDict:_tempDict];
    }
}

-(void)refreshTableInformation
{
    if (![self activityIndicator]) {
        [self setActivityIndicator:[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)]];
    }
    
    [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:[self activityIndicator]]];
    
    if (![[self activityIndicator] isAnimating]) {
        [[self activityIndicator] startAnimating];
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/mentions.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setMentions:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            if ([[self mentions] count] == 0) {
                [self goMakeFriends];
            }
            
            [[self tableView] reloadData];
            
            [[self refreshControl] endRefreshing];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
        
        [[self activityIndicator] stopAnimating];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"enable_cell" object:nil];
    }];
    
    
}

-(void)goMakeFriends
{
    BlockAlertView *mentionsError = [[BlockAlertView alloc] initWithTitle:@"No mentions!" message:@"Man, you need to make some friends!  Go to the Users tab and talk to someone!"];
    
    [mentionsError setCancelButtonWithTitle:@"OK" block:nil];
    
    [mentionsError show];
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
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self mentions][[indexPathOfTappedRow row]][@"sender_user_id"]]];
    
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

-(void)repostSwitchToSelectedUser:(NSNotification *)aNotification
{
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:[self view]];
    [progressHUD setMode:MBProgressHUDModeIndeterminate];
    [progressHUD setLabelText:@"Loading User..."];
    [progressHUD setDelegate:self];
    
    [[self view] addSubview:progressHUD];
    
    [progressHUD show:YES];
    
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self mentions][[indexPathOfTappedRow row]][@"repost_user_id"]]];
    
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

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
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
@end
