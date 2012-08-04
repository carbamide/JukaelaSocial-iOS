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

@interface FeedViewController ()
@property (strong, nonatomic) NSString *stringToPost;
@property (strong, nonatomic) ODRefreshControl *oldRefreshControl;
@property (nonatomic) ChangeType currentChangeType;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableInformation) name:@"refresh_your_tables" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setChangeType:) name:@"set_change_type" object:nil];
    
    if (![self theFeed]) {
        [self refreshTableInformation];
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

-(void)setChangeType:(NSNotification *)number
{
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
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Some kind of madness has happened. Your post was posted but the view wasn't updated properly."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil];
        
        [errorAlert show];
    }
}

-(void)composePost:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"ShowPostView" sender:self];
}

-(void)refreshTableInformation
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {        
        [self setTheFeed:nil];
        
        [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
                        
        if ([self currentChangeType] == INSERT_POST) {
            [[self tableView] beginUpdates];
            [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] endUpdates];
        }
        else if ([self currentChangeType] == DELETE_POST) {
            [[self tableView] beginUpdates];
            [[self tableView] deleteRowsAtIndexPaths:@[[[self tableView] indexPathForSelectedRow]] withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] endUpdates];
        }
        else {
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
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica-Bold" size:12.0];
    
    CGSize constraintSize = CGSizeMake(215, 140);
    CGSize labelSize = [[self theFeed][[indexPath row]][@"content"] sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
        
    if (labelSize.height < 40) {
        return 95;
    }
    else {
        return labelSize.height + 55;
    }
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
    
    if ([self theFeed][[indexPath row]][@"content"]) {
        [[cell textLabel] setText:[self theFeed][[indexPath row]][@"content"]];
    }
    else {
        [[cell textLabel] setText:@"Loading..."];
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
    RIButtonItem *replyButton = [RIButtonItem itemWithLabel:@"Reply"];
    RIButtonItem *repostButton = [RIButtonItem itemWithLabel:@"Repost"];
    RIButtonItem *showUserButton = [RIButtonItem itemWithLabel:@"Show User..."];
    RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:@"Cancel"];
    RIButtonItem *deleteButton = [RIButtonItem itemWithLabel:@"Delete Post"];
    
    [deleteButton setAction:^{
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
            
            [self refreshTableInformation];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }];
    }];
    
    [replyButton setAction:^{
        [self performSegueWithIdentifier:@"ShowReplyView" sender:self];
    }];
    
    [showUserButton setAction:^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[indexPath row]][@"user_id"]]];
        
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
    
    if ([[NSString stringWithFormat:@"%@", [self theFeed][[[[self tableView] indexPathForSelectedRow] row]][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
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
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@ ", [self theFeed][[[[self tableView] indexPathForSelectedRow] row]][@"username"]]];
        
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
    
    NSString *documentsDirectory = tempArray[0];
    
    return documentsDirectory;
}

@end
