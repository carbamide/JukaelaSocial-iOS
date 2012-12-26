//
//  DirectMessagesViewController.m
//  Jukaela
//
//  Created by Josh on 12/9/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/message.h>
#import "CellBackground.h"
#import "DirectMessagesViewController.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "MBProgressHUD.h"
#import "NormalCellView.h"
#import "ShowUserViewController.h"
#import "SORelativeDateTransformer.h"
#import "SVModalWebViewController.h"


@interface DirectMessagesViewController ()
@property (strong, nonatomic) NSArray *messagesArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDictionary *tempDict;

@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) YIFullScreenScroll *fullScreenDelegate;
@end

@implementation DirectMessagesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [_fullScreenDelegate layoutTabBarController];
    
    [kAppDelegate setCurrentViewController:self];
    
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doubleTap:) name:kDoubleTapNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToSelectedUser:) name:kSendToUserNotification object:nil];
    
    _fullScreenDelegate = [[YIFullScreenScroll alloc] initWithViewController:self];
    
    JRefreshControl *refreshControl = [[JRefreshControl alloc] init];
    
    [refreshControl setTintColor:[UIColor blackColor]];
    
    [refreshControl addTarget:self action:@selector(getMessages) forControlEvents:UIControlEventValueChanged];
    
    [self setRefreshControl:refreshControl];
    
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(showComposer:)]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [[self view] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLoadUserWithUsernameNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        NSString *usernameString = [aNotification userInfo][@"username"];
        
        [self requestWithUsername:usernameString];
    }];
    
	[self getMessages];
}

-(void)showComposer:(id)sender
{
    [self performSegueWithIdentifier:kShowCompose sender:nil];;
}

-(void)getMessages
{
    if ([self messagesArray]) {
        [self setMessagesArray:nil];
    }
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/direct_messages.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setMessagesArray:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[self tableView] reloadData];
            
            [[ActivityManager sharedManager] decrementActivityCount];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading your direct messages..  Please logout and log back in."];
        }
        
        [[self refreshControl] endRefreshing];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentText = [self messagesArray][[indexPath row]][kContent];
    
    CGSize constraint = CGSizeMake(300, 20000);
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont fontWithName:kFontPreference size:17] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    return contentSize.height + 50 + 10;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self messagesArray] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DirectMessagesCell";
    
    NormalCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[NormalCellView alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell setBackgroundView:[[CellBackground alloc] init]];
    }
    
    [[cell contentText] setFontName:kFontPreference];
    [[cell contentText] setFontSize:17];
    
    if ([self messagesArray][[indexPath row]][kContent] && [self messagesArray][[indexPath row]][kContent] != [NSNull null]) {
        [[cell contentText] setText:[self messagesArray][[indexPath row]][kContent]];
    }
    [[cell nameLabel] setText:[self messagesArray][[indexPath row]][@"from_name"]];
    
    if ([self messagesArray][[indexPath row]][@"from_username"] && [self messagesArray][[indexPath row]][@"from_username"] != [NSNull null]) {
        [[cell usernameLabel] setText:[NSString stringWithFormat:@"@%@", [self messagesArray][[indexPath row]][@"from_username"]]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self messagesArray][[indexPath row]][kCreationDate] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self messagesArray][[indexPath row]][@"from_user_id"]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self messagesArray][[indexPath row]][@"from_email"] withSize:65]]];
            
#if (TARGET_IPHONE_SIMULATOR)
            image = [JEImages normalize:image];
#endif
            UIImage *resizedImage = [image thumbnailImage:65 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
                
                if ([indexPath isEqual:cellIndexPath]) {
                    [[cell imageView] setImage:resizedImage];
                    [cell setNeedsDisplay];
                }
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self messagesArray][[indexPath row]][kUserID]]];
            });
        });
        
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
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

-(void)doubleTap:(NSNotification *)aNotification
{
    if ([kAppDelegate currentViewController] == self) {
        [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
    }
}

- (void)handleURL:(NSURL*)url
{
    [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
    
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[url absoluteString]];
    
    [webViewController setBarsTintColor:[UIColor darkGrayColor]];
    
    [self presentViewController:webViewController animated:YES completion:nil];
}

-(void)requestWithUsername:(NSString *)username
{
    if ([kAppDelegate currentViewController] == self) {
        [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
        
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithWindow:[[self view] window]];
        [progressHUD setMode:MBProgressHUDModeIndeterminate];
        [progressHUD setLabelText:@"Loading User..."];
        [progressHUD setDelegate:self];
        
        [[[self view] window] addSubview:progressHUD];
        
        [progressHUD show:YES];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/user_from_username.json", kSocialURL]];
        
        NSString *requestString = [RequestFactory userFromUsername:username];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            }
            else {
                [Helpers errorAndLogout:self withMessage:@"There was an error loading the user.  Please logout and log back in."];
            }
            
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [progressHUD hide:YES];
            
            [self performSegueWithIdentifier:kShowUser sender:nil];
        }];
    }
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:kShowUser]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ShowUserViewController *viewController = (ShowUserViewController *)[navigationController topViewController];
        
        [viewController setUserDict:_tempDict];
    }
}

-(void)switchToSelectedUser:(NSNotification *)aNotification
{
    if ([kAppDelegate currentViewController] == self) {
        [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
        
        if (![self progressHUD]) {
            [self setProgressHUD:[[MBProgressHUD alloc] initWithWindow:[[self view] window]]];
        }
        [[self progressHUD] setMode:MBProgressHUDModeIndeterminate];
        [[self progressHUD] setLabelText:@"Loading User..."];
        [[self progressHUD] setDelegate:self];
        
        [[[self view] window] addSubview:[self progressHUD]];
        
        [[self progressHUD] show:YES];
        
        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][kIndexPath];
        
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self messagesArray][[indexPathOfTappedRow row]][kUserID]]];
        
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
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [[self progressHUD] hide:YES];
            
            [self performSegueWithIdentifier:kShowUser sender:nil];
        }];
    }
}


@end
