//
//  MentionsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 8/29/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import "ClearLabelsCellView.h"
#import "GradientView.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "NSDate+RailsDateParser.h"
#import "MentionsViewController.h"
#import "PostViewController.h"
#import "ShowUserViewController.h"
#import "SORelativeDateTransformer.h"

@interface MentionsViewController ()
@property (strong, nonatomic) ODRefreshControl *oldRefreshControl;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) NSNotificationCenter *refreshTableNotificationCenter;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;

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

- (void)viewDidLoad
{
    [self refreshTableInformation];
    
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
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composePost:)];
    
    [[self navigationItem] setRightBarButtonItem:composeButton];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
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
    NSString *nameText = [self mentions][[indexPath row]][@"sender_name"];
    
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
    return [[self mentions] count];
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
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self mentions][[indexPath row]][@"sender_email"]]]]];
    
	if (image) {
		[[cell imageView] setImage:image];
        [cell setNeedsDisplay];
	}
    else {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
		objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
		
		dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self mentions][[indexPath row]][@"sender_email"]]]];
			
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
				
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self mentions][[indexPath row]][@"sender_email"]]];
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
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    [self setTempIndexPath:indexPathOfTappedRow];
    
    BlockActionSheet *cellActionSheet = [[BlockActionSheet alloc] initWithTitle:nil];
    
    [cellActionSheet addButtonWithTitle:@"Reply" block:^{
        [self performSegueWithIdentifier:@"ShowReplyView" sender:self];
        
    }];
    
    [cellActionSheet addButtonWithTitle:@"Repost" block:^{
        [self performSegueWithIdentifier:@"ShowRepostView" sender:self];
        
    }];
    
    if ([[NSString stringWithFormat:@"%@", [self mentions][[indexPathOfTappedRow row]][@"sender_user_id"]] isEqualToString:[kAppDelegate userID]]) {
        [cellActionSheet setDestructiveButtonWithTitle:@"Delete Post" block:^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, [self mentions][[indexPath row]][@"id"]]];
            
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
    else if ([[segue identifier] isEqualToString:@"ShowRepostView"]) {
        UITableViewCell *tempCell = [[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setRepostString:[NSString stringWithFormat:@"%@", [[tempCell textLabel] text]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUser"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ShowUserViewController *viewController = (ShowUserViewController *)[navigationController topViewController];
        
        [viewController setUserDict:_tempDict];
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
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/mentions.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setMentions:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[self tableView] reloadData];
            
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
                [[self refreshControl] endRefreshing];
            }
            else {
                [_oldRefreshControl endRefreshing];
            }
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
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

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

@end