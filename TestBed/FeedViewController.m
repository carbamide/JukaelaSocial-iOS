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

@interface FeedViewController ()
@property (strong, nonatomic) NSString *stringToPost;
@property (strong, nonatomic) ODRefreshControl *oldRefreshControl;
@end

@implementation FeedViewController

-(id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)viewDidLoad
{
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
    
    if (![self theFeed]) {
        [self refreshTableInformation:OTHER_CHANGE_TYPE withIndexPath:nil];
    }
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composePost:)];
    
    [[self navigationItem] setRightBarButtonItem:composeButton];
    
    [[self navigationItem] setHidesBackButton:YES];
    
    [super viewDidLoad];
}

-(void)composePost:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"ShowPostView" sender:self];
}

-(void)refreshTableInformation:(ChangeType)changeType withIndexPath:(NSIndexPath *)indexPath
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
        
        if (changeType == INSERT_POST) {
            [[self tableView] beginUpdates];
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] endUpdates];
        }
        else if (changeType == DELETE_POST) {
            [[self tableView] beginUpdates];
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] endUpdates];
        }
        else {
            [[self tableView] reloadData];
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (NSClassFromString(@"UIRefreshControl")) {
            [[self refreshControl] endRefreshing];
        }
        else {
            [_oldRefreshControl endRefreshing];
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
    return 100;
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
    
    [[cell textLabel] setFont:[UIFont fontWithName:@"Helvetica" size:14]];
    
    [[cell textLabel] setLineBreakMode:UILineBreakModeWordWrap];
    [[cell textLabel] setNumberOfLines:5];
    
    if ([[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"content"]) {
        [[cell textLabel] setText:[[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"content"]];
    }
    else {
        [[cell textLabel] setText:@"Loading..."];
    }
    
    if ([[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"name"] && [[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"name"] != [NSNull null]) {
        [[cell nameLabel] setText:[[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"name"]];
    }
    else {
        if ([[self nameDict] objectForKey:[[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"user_id"]]) {
            [[cell nameLabel] setText:[NSString stringWithFormat:@"%@", [[self nameDict] objectForKey:[[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"user_id"]]]];
        }
        else {
            [[cell nameLabel] setText:@"Loading..."];
        }
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"created_at"] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[NSString stringWithFormat:@"%@ ago", [[[NSDate alloc] init] distanceOfTimeInWordsSinceDate:tempDate]]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"email"]]]]];
    
	if (image) {
		[[cell imageView] setImage:image];
        [cell setNeedsDisplay];
	}
    else {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
		objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
		
		dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"email"]]]];
			
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
				
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"email"]]];
			});
		});
	}
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RIButtonItem *replyButton = [RIButtonItem itemWithLabel:@"Reply"];
    RIButtonItem *repostButton = [RIButtonItem itemWithLabel:@"Repost"];
    RIButtonItem *showUserButton = [RIButtonItem itemWithLabel:@"Show User..."];
    RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:@"Cancel"];
    RIButtonItem *deleteButton = [RIButtonItem itemWithLabel:@"Delete Post"];
    
    [deleteButton setAction:^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, [[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"id"]]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"DELETE"];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
            
            [self refreshTableInformation:DELETE_POST withIndexPath:indexPath];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }];
    }];
    
    [replyButton setAction:^{
        [self performSegueWithIdentifier:@"ShowReplyView" sender:self];
    }];
    
    [showUserButton setAction:^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [[[self theFeed] objectAtIndex:[indexPath row]] objectForKey:@"user_id"]]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self performSegueWithIdentifier:@"ShowUser" sender:nil];
        }];
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
                                                         otherButtonItems:replyButton, repostButton, showUserButton, nil];
    
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
    
    if ([[NSString stringWithFormat:@"%@", [[[self theFeed] objectAtIndex:[[[self tableView] indexPathForSelectedRow] row]] objectForKey:@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
        NSInteger deleteIndex = [cellActionSheet addButtonItem:deleteButton];
        
        [cellActionSheet setDestructiveButtonIndex:deleteIndex];
    }
    
    NSInteger cancelIndex = [cellActionSheet addButtonItem:cancelButton];
    
    [cellActionSheet setCancelButtonIndex:cancelIndex];
    
    [cellActionSheet showFromTabBar:[[self tabBarController] tabBar]];
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
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@ ", [[[self theFeed] objectAtIndex:[[[self tableView] indexPathForSelectedRow] row]] objectForKey:@"username"]]];
        
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

@end
