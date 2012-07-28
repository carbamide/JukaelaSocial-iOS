//
//  UsersPostsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/17/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import "ClearLabelsCellView.h"
#import "GradientView.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "NSDate+RailsDateParser.h"
#import "UsersPostsViewController.h"
#import "PostViewController.h"

@interface UsersPostsViewController ()
@property (strong, nonatomic) ODRefreshControl *oldRefreshControl;
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
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_0
    if (NSClassFromString(@"UIRefreshControl")) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        
        [refreshControl setTintColor:[UIColor blackColor]];
        
        [refreshControl addTarget:self action:@selector(refreshTableInformation) forControlEvents:UIControlEventValueChanged];
        
        [self setRefreshControl:refreshControl];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableInformation) name:@"refresh_your_tables" object:nil];
    }
    else {
        _oldRefreshControl = [[ODRefreshControl alloc] initInScrollView:[self tableView]];
        
        [_oldRefreshControl setTintColor:[UIColor blackColor]];
        
        [_oldRefreshControl addTarget:self action:@selector(refreshTableInformation) forControlEvents:UIControlEventValueChanged];
    }
#else
    _oldRefreshControl = [[ODRefreshControl alloc] initInScrollView:[self tableView]];
    
    [_oldRefreshControl setTintColor:[UIColor blackColor]];
    
    [_oldRefreshControl addTarget:self action:@selector(refreshTableInformation) forControlEvents:UIControlEventValueChanged];
#endif
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    [self setTitle:[[[self userPostArray] lastObject] objectForKey:@"name"]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [super viewDidLoad];
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
    return 100;
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
    static NSString *CellIdentifier = @"Cell";
    
    ClearLabelsCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[ClearLabelsCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        [cell setBackgroundView:[[GradientView alloc] init]];
    }
    
    [[cell textLabel] setFont:[UIFont fontWithName:@"Helvetica" size:14]];
    
    [[cell textLabel] setLineBreakMode:UILineBreakModeWordWrap];
    [[cell textLabel] setNumberOfLines:5];
    
    if ([[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"content"]) {
        [[cell textLabel] setText:[[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"content"]];
    }
    else {
        [[cell textLabel] setText:@"Loading..."];
    }
    
    if ([[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"name"] && [[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"name"] != [NSNull null]) {
        [[cell nameLabel] setText:[[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"name"]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"created_at"] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[NSString stringWithFormat:@"%@ ago", [[[NSDate alloc] init] distanceOfTimeInWordsSinceDate:tempDate]]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"email"]]]]];
    
	if (image) {
		[[cell imageView] setImage:image];
        [cell setNeedsDisplay];
	}
    else {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
		objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
		
		dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"email"]]]];
			
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
				
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"email"]]];
			});
		});
	}
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RIButtonItem *replyButton = [RIButtonItem itemWithLabel:@"Reply"];
    RIButtonItem *repostButton = [RIButtonItem itemWithLabel:@"Repost"];
    RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:@"Cancel"];
    RIButtonItem *deleteButton = [RIButtonItem itemWithLabel:@"Delete Post"];
    
    [deleteButton setAction:^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, [[[self userPostArray] objectAtIndex:[indexPath row]] objectForKey:@"id"]]];
        
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
    
    [replyButton setAction:^{
        [self performSegueWithIdentifier:@"ShowReplyView" sender:self];
    }];
    
    [repostButton setAction:^{
        [self performSegueWithIdentifier:@"ShowRepostView" sender:self];
    }];
    
    [cancelButton setAction:^{
        [[[self tableView] cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
        
        return;
    }];
    
    UIActionSheet *cellActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                         cancelButtonItem:nil
                                                    destructiveButtonItem:nil
                                                         otherButtonItems:replyButton, repostButton, nil];
    
    NSString *labelString = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    
    NSArray *matches = [linkDetector matchesInString:labelString options:0 range:NSMakeRange(0, [labelString length])];
    
    for (NSTextCheckingResult *match in matches) {
        if ([match resultType] == NSTextCheckingTypeLink) {
            NSURL *url = [match URL];
            RIButtonItem *urlButton = [RIButtonItem itemWithLabel:[url absoluteString]];
            
            [urlButton setAction:^{
                [[UIApplication sharedApplication] openURL:url];
            }];
            
            [cellActionSheet addButtonItem:urlButton];
        }
    }
    
    if ([[NSString stringWithFormat:@"%@", [[[self userPostArray] objectAtIndex:[[[self tableView] indexPathForSelectedRow] row]] objectForKey:@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
        NSInteger deleteIndex = [cellActionSheet addButtonItem:deleteButton];
        
        [cellActionSheet setDestructiveButtonIndex:deleteIndex];
    }
    
    NSInteger cancelIndex = [cellActionSheet addButtonItem:cancelButton];
    
    [cellActionSheet setCancelButtonIndex:cancelIndex];
    
    [cellActionSheet showInView:[self view]];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowReplyView"]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@ ", [[[self userPostArray] objectAtIndex:[[[self tableView] indexPathForSelectedRow] row]] objectForKey:@"username"]]];
        
        [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:@"ShowRepostView"]) {
        UITableViewCell *tempCell = [[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setRepostString:[NSString stringWithFormat:@"%@", [[tempCell textLabel] text]]];
        
        [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
    }
}

-(NSString *)documentsPath
{
    NSArray *tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [tempArray objectAtIndex:0];
    
    return documentsDirectory;
}

-(void)refreshTableInformation
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userID]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self setUserPostArray:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
        
        [[self tableView] reloadData];
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_0
        if (NSClassFromString(@"UIRefreshControl")) {
            [[self refreshControl] endRefreshing];
        }
        else {
            [_oldRefreshControl endRefreshing];
        }
#else
        [_oldRefreshControl endRefreshing];
#endif
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}
@end
