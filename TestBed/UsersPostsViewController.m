//
//  UsersPostsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/17/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import "NormalCellView.h"
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "NSDate+RailsDateParser.h"
#import "UsersPostsViewController.h"
#import "PostViewController.h"
#import "NormalCellView.h"
#import "ShareObject.h"
#import "SORelativeDateTransformer.h"
#import "WBSuccessNoticeView.h"
#import "NormalWithImageCellView.h"
#import "UIImageView+Curled.h"

@interface UsersPostsViewController ()
@property (strong, nonatomic) ODRefreshControl *oldRefreshControl;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) NSNotificationCenter *refreshTableNotificationCenter;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;

@end

@implementation UsersPostsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        
        [refreshControl setTintColor:[UIColor blackColor]];
        
        [refreshControl addTarget:self action:@selector(refreshTableInformation) forControlEvents:UIControlEventValueChanged];
        
        [self setRefreshControl:refreshControl];
    }
    else {
        _oldRefreshControl = [[ODRefreshControl alloc] initInScrollView:[self tableView]];
        
        [_oldRefreshControl setTintColor:[UIColor blackColor]];
        
        [_oldRefreshControl addTarget:self action:@selector(refreshTableInformation) forControlEvents:UIControlEventValueChanged];
    }
    
    [[self tableView] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    [self setTitle:[[self userPostArray] lastObject][@"name"]];
    
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [[self navigationController] setToolbarHidden:YES animated:YES];
    
    [super viewDidLoad];
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
    NSString *contentText = [self userPostArray][[indexPath row]][@"content"];
    
    CGSize constraint = CGSizeMake(275, 20000);
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont fontWithName:@"Helvetica-Light" size:14] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height;
    
    if ([self userPostArray][[indexPath row]][@"repost_user_id"] && [self userPostArray][[indexPath row]][@"repost_user_id"] != [NSNull null]) {
        height = jMAX(contentSize.height + 50 + 10, 90);
    }
    else {
        height = jMAX(contentSize.height + 50 + 10, 75);
    }
    
    return height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self userPostArray] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FeedViewCell";
    static NSString *CellWithImageCellIdentifier = @"CellWithImageCellIdentifier";
    
    id cell = nil;
    
    if ([self userPostArray][[indexPath row]][@"image_url"] && [self userPostArray][[indexPath row]][@"image_url"] != [NSNull null]) {
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
    
    if ([self userPostArray][[indexPath row]][@"image_url"] && [self userPostArray][[indexPath row]][@"image_url"] != [NSNull null]) {
        if (![[cell externalImage] image]) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            
            objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
            
            dispatch_async(queue, ^{
                NSMutableString *tempString = [NSMutableString stringWithString:[self userPostArray][[indexPath row]][@"image_url"]];
                
                [tempString insertString:@"s" atIndex:24];
                
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[cell externalImage] setImage:image borderWidth:2 shadowDepth:5 controlPointXOffset:20 controlPointYOffset:25];
                });
            });
        }
    }
    
    [[cell contentText] setFontName:@"Helvetica-Light"];
    [[cell contentText] setFontSize:14];
    
    if ([self userPostArray][[indexPath row]][@"content"]) {
        [[cell contentText] setText:[self userPostArray][[indexPath row]][@"content"]];
    }
    else {
        [[cell contentText] setText:@"Loading..."];
    }
    
    if ([self userPostArray][[indexPath row]][@"name"] && [self userPostArray][[indexPath row]][@"name"] != [NSNull null]) {
        [[cell nameLabel] setText:[self userPostArray][[indexPath row]][@"name"]];
    }
    
    if ([self userPostArray][[indexPath row]][@"username"] && [self userPostArray][[indexPath row]][@"username"] != [NSNull null]) {
        [[cell usernameLabel] setText:[self userPostArray][[indexPath row]][@"username"]];
    }
    
    if ([self userPostArray][[indexPath row]][@"repost_user_id"] && [self userPostArray][[indexPath row]][@"repost_user_id"] != [NSNull null]) {
        CGSize contentSize = [[self userPostArray][[indexPath row]][@"content"] sizeWithFont:[UIFont fontWithName:@"Helvetica-Light" size:17]
                                                                           constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                               lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize nameSize = [[self userPostArray][[indexPath row]][@"name"] sizeWithFont:[UIFont fontWithName:@"Helvetica-Light" size:14]
                                                                     constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                         lineBreakMode:NSLineBreakByWordWrapping];
        
        CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 75);
        
        if ([[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
            [[cell repostedNameLabel] setFrame:CGRectMake(12, height, 228, 20)];
        }
        else {
            [[cell repostedNameLabel] setFrame:CGRectMake(86, height, 228, 20)];
        }
        [[cell repostedNameLabel] setText:[NSString stringWithFormat:@"Reposted by %@", [self userPostArray][[indexPath row]][@"repost_name"]]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self userPostArray][[indexPath row]][@"created_at"] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][@"user_id"]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][@"user_id"]]]] error:nil];
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetween:[NSDate date] and:attributes[NSFileCreationDate]] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userPostArray][[indexPath row]][@"email"] withSize:40]]];
                    
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
                        
                        [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][@"user_id"]]];
                    });
                });
            }
        }
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userPostArray][[indexPath row]][@"email"] withSize:40]]];
            
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
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][@"user_id"]]];
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
    if ([[self tabBarController] selectedIndex] == 0) {
        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
        
        [self setTempIndexPath:indexPathOfTappedRow];
        
        BlockActionSheet *cellActionSheet = [[BlockActionSheet alloc] initWithTitle:nil];
        
        [cellActionSheet addButtonWithTitle:@"Reply" block:^{
            [self performSegueWithIdentifier:@"ShowReplyView" sender:self];
            
        }];
        
        [cellActionSheet addButtonWithTitle:@"Repost" block:^{
            [ShareObject repost:indexPathOfTappedRow fromArray:[self userPostArray] withViewController:(FeedViewController *)self];
            
        }];
        
        if ([[NSString stringWithFormat:@"%@", [self userPostArray][[indexPathOfTappedRow row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
            [cellActionSheet setDestructiveButtonWithTitle:@"Delete Post" block:^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                
                NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
                
                [tempCell disableCell];
                
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, [self userPostArray][[indexPathOfTappedRow row]][@"id"]]];
                
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
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowReplyView"]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [self userPostArray][[[self tempIndexPath] row]][@"username"]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:@"ShowRepostView"]) {
        UITableViewCell *tempCell = [[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setRepostString:[NSString stringWithFormat:@"%@", [[tempCell textLabel] text]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
}


-(void)refreshTableInformation
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userID]]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setUserPostArray:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[self tableView] reloadData];
            
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
                [[self refreshControl] endRefreshing];
            }
            else {
                [_oldRefreshControl endRefreshing];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"enable_cell" object:nil];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"enable_cell" object:nil];
    }];
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

@end
