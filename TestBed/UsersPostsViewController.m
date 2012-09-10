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
#import "GradientView.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "NSDate+RailsDateParser.h"
#import "UsersPostsViewController.h"
#import "PostViewController.h"
#import "SelfCellView.h"
#import "SORelativeDateTransformer.h"
#import "WBSuccessNoticeView.h"

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
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
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
    NSString *nameText = [self userPostArray][[indexPath row]][@"name"];
    
    CGSize constraint = CGSizeMake(215 - (7.5 * 2), 20000);
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:12] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize nameSize = [nameText sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 75);
    
    return height + (10 * 2);
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
    static NSString *SelfCellIdentifier = @"SelfFeedViewCell";
    id cell = nil;
    
    if ([[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
        cell = [tableView dequeueReusableCellWithIdentifier:SelfCellIdentifier];
        
        if (!cell) {
            cell = [[SelfCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SelfCellIdentifier];
            
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
    
    [[cell contentText] setFontName:@"Helvetica"];
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
        CGSize contentSize = [[self userPostArray][[indexPath row]][@"content"] sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]
                                                                           constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                               lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize nameSize = [[self userPostArray][[indexPath row]][@"name"] sizeWithFont:[UIFont systemFontOfSize:12]
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
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][@"email"]]]]];
    
    [[cell activityIndicator] startAnimating];
    
    if (image) {
        [[cell activityIndicator] stopAnimating];
        
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
    }
    else {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
		objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
		
		dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userPostArray][[indexPath row]][@"email"]]]];
			
#if (TARGET_IPHONE_SIMULATOR)
            image = [JEImages normalize:image];
#endif
            UIImage *resizedImage = [image thumbnailImage:55 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
				
				if ([indexPath isEqual:cellIndexPath]) {
					[[cell imageView] setImage:resizedImage];
                    [cell setNeedsDisplay];
				}
				
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][@"email"]]];
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
            [self repost:indexPathOfTappedRow];
            
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

-(void)repost:(NSIndexPath *)indexPathOfCell
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@/repost.json", kSocialURL, [self userPostArray][[indexPathOfCell row]][@"id"]]];
    
    NSData *tempData = [[[self userPostArray][[indexPathOfCell row]][@"content"] stringWithSlashEscapes] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *stringToSendAsContent = [[NSString alloc] initWithData:tempData encoding:NSASCIIStringEncoding];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", stringToSendAsContent, [kAppDelegate userID]];
    
    NSLog(@"%@\n%@", [url absoluteString], requestString);
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"jukaela_successful" object:nil];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            WBSuccessNoticeView *successNotice = [[WBSuccessNoticeView alloc] initWithView:[self view] title:@"Reposted"];
            
            [successNotice show];
        }
        else {
            NSLog(@"Error");
        }
    }];
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

-(NSString *)documentsPath
{
    NSArray *tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = tempArray[0];
    
    return documentsDirectory;
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
