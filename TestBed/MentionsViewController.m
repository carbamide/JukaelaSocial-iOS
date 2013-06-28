//
//  MentionsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 8/29/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "MentionsViewController.h"
#import "NormalCellView.h"
#import "NormalWithImageCellView.h"
#import "PostViewController.h"
#import "ShowUserViewController.h"
#import "SORelativeDateTransformer.h"
#import "SVModalWebViewController.h"
#import "WBSuccessNoticeView.h"
#import "WBErrorNoticeView.h"

@interface MentionsViewController ()
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doubleTap:) name:kDoubleTapNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToSelectedUser:) name:kSendToUserNotification object:nil];
    
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDoubleTapNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSendToUserNotification object:nil];
    
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [self setExternalImageCache:[[NSCache alloc] init]];
    
    [self refreshTableInformation];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    [refreshControl setTintColor:[UIColor blackColor]];
    
    [refreshControl addTarget:self action:@selector(refreshTableInformation) forControlEvents:UIControlEventValueChanged];
    
    [self setRefreshControl:refreshControl];
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composePost:)];
    
    [[self navigationItem] setRightBarButtonItem:composeButton];
        
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLoadUserWithUsernameNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        NSString *usernameString = [aNotification userInfo][@"username"];
        
        [self requestWithUsername:usernameString];
    }];
    
    [super viewDidLoad];
}

-(void)composePost:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:kShowPostView sender:self];
}

-(void)setupNotifications
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [defaultCenter addObserverForName:kRefreshYourTablesNotification object:nil queue:mainQueue usingBlock:^(NSNotification *notification) {
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
    NSString *contentText = [self mentions][[indexPath row]][kContent];
    
    CGSize constraint = CGSizeMake(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 750 : 300, 20000);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize contentSize = [contentText sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
    
    if ([self mentions][[indexPath row]][kRepostUserID] && [self mentions][[indexPath row]][kRepostUserID] != [NSNull null]) {
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
    
    if ([self mentions][[indexPath row]][kImageURL] && [self mentions][[indexPath row]][kImageURL] != [NSNull null]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellWithImageCellIdentifier];
        
        if (!cell) {
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
    
    if ([self mentions][[indexPath row]][kImageURL] && [self mentions][[indexPath row]][kImageURL] != [NSNull null]) {
        NSMutableString *tempString = [NSMutableString stringWithString:[self mentions][[indexPath row]][kImageURL]];
        
        NSString *tempExtensionString = [NSString stringWithFormat:@".%@", [tempString pathExtension]];
        
        [tempString stringByReplacingOccurrencesOfString:tempExtensionString withString:@""];
        [tempString appendFormat:@"s"];
        [tempString appendString:tempExtensionString];
        
        if (![[cell externalImage] image]) {
            if ([[self externalImageCache] objectForKey:indexPath]) {
                [[cell externalImage] setImage:[[self externalImageCache] objectForKey:indexPath]];
            }
            else if ([[NSFileManager defaultManager] fileExistsAtPath:[[Helpers documentsPath] stringByAppendingPathComponent:[tempString lastPathComponent]]]) {
                UIImage *externalImageFromDisk = [UIImage imageWithData:[NSData dataWithContentsOfFile:[[Helpers documentsPath] stringByAppendingPathComponent:[tempString lastPathComponent]]]];
                
                [[cell externalImage] setImage:externalImageFromDisk];
                
                if (externalImageFromDisk) {
                    [[self externalImageCache] setObject:externalImageFromDisk forKey:indexPath];
                }
            }
            else {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
                
                objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
                
                dispatch_async(queue, ^{
                    
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
                    
                    if (image) {
                        [[self externalImageCache] setObject:image forKey:indexPath];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[cell externalImage] setImage:image];
                        
                        [Helpers saveImage:image withFileName:[tempString lastPathComponent]];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            NSString *path = [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithString:[tempString lastPathComponent]]];
                            
                            NSData *data = nil;
                            
                            if ([[tempString pathExtension] isEqualToString:@".png"]) {
                                data = UIImagePNGRepresentation(image);
                            }
                            else {
                                data = UIImageJPEGRepresentation(image, 1.0);
                            }
                            
                            [data writeToFile:path atomically:YES];
                        });
                    });
                });
            }
        }
    }
    
    if ([self mentions][[indexPath row]][kContent]) {
        [[cell contentText] setText:[self mentions][[indexPath row]][kContent]];
    }
    else {
        [[cell contentText] setText:@"Loading..."];
    }
    
    if ([self mentions][[indexPath row]][@"sender_name"] && [self mentions][[indexPath row]][@"sender_name"] != [NSNull null]) {
        [[cell nameLabel] setText:[self mentions][[indexPath row]][@"sender_name"]];
    }
    
    if ([self mentions][[indexPath row]][@"sender_username"] && [self mentions][[indexPath row]][@"sender_username"] != [NSNull null]) {
        [[cell usernameLabel] setText:[NSString stringWithFormat:@"@%@", [self mentions][[indexPath row]][@"sender_username"]]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self mentions][[indexPath row]][kCreationDate] withFormatter:[self dateFormatter]];
    
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

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == ([[self mentions] count] - 1)) {
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/pages/mentions.json", kSocialURL]];
        
        NSString *requestString = [RequestFactory feedRequestFrom:[[self mentions] count] to:[[self mentions] count] + 20];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {                
                NSMutableArray *tempArray = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
                
                NSInteger oldTableViewCount = [[self mentions] count];
                
                NSMutableArray *rehashOfOldArray = [NSMutableArray arrayWithArray:[self mentions]];
                
                [rehashOfOldArray addObjectsFromArray:tempArray];
                
                [self setMentions:rehashOfOldArray];
                
                @try {
                    [[self tableView] beginUpdates];
                    
                    int tempArrayCount = [tempArray count];
                    
                    for (int i = 0; i < tempArrayCount; i++) {
                        NSInteger rowInt = oldTableViewCount + i;
                        
                        [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowInt inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    }
                    [[self tableView] endUpdates];
                }
                @catch (NSException *exception) {
                    if (exception) {
                        NSLog(@"%@", exception);
                    }
                    
                    [[self tableView] reloadData];
                }
                @finally {
                    [[self activityIndicator] stopAnimating];
                    
                    NSLog(@"Inside finally");
                }
            }
            else {
                WBErrorNoticeView *notice = [[WBErrorNoticeView alloc] initWithView:[self view] title:@"Error reloading Feed"];
                
                [notice show];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
        }];
        [[ActivityManager sharedManager] decrementActivityCount];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)doubleTap:(NSNotification *)aNotification
{
    if ([kAppDelegate currentViewController] == self) {

        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][kIndexPath];
        
        [self setTempIndexPath:indexPathOfTappedRow];
        
        RIButtonItem *replyButton = [RIButtonItem itemWithLabel:@"Reply" action:^{
            [self performSegueWithIdentifier:kShowReplyView sender:self];
        }];
        
        RIButtonItem *deletePostButton = nil;
                
        
        if ([[NSString stringWithFormat:@"%@", [self mentions][[indexPathOfTappedRow row]][@"sender_user_id"]] isEqualToString:[kAppDelegate userID]]) {
            deletePostButton = [RIButtonItem itemWithLabel:@"Delete Post" action:^{
                [[ActivityManager sharedManager] incrementActivityCount];
                
                NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
                
                [tempCell disableCell];
                
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/mentions/%@.json", kSocialURL, [self mentions][[indexPathOfTappedRow row]][kID]]];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
                
                [request setHTTPMethod:@"DELETE"];
                [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
                [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
                
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
                    
                    [self refreshTableInformation];
                    
                    [[ActivityManager sharedManager] decrementActivityCount];
                }];
            }];
        }
        
        UIActionSheet *cellActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] destructiveButtonItem:deletePostButton otherButtonItems:replyButton, nil];
        
        [cellActionSheet showFromTabBar:[[self tabBarController] tabBar]];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:kShowReplyView]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [self mentions][[[self tempIndexPath] row]][@"sender_username"]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowUser]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ShowUserViewController *viewController = (ShowUserViewController *)[navigationController topViewController];
        
        [viewController setUserDict:_tempDict];
    }
}

-(void)refreshTableInformation
{
    if (![self activityIndicator]) {
        [self setActivityIndicator:[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)]];
                
        [[self activityIndicator] setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];

    }
    
    //FIXME
    //[[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:[self activityIndicator]]];
    
    if (![[self activityIndicator] isAnimating]) {
        [[self activityIndicator] startAnimating];
    }
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/pages/mentions.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory feedRequestFrom:0 to:20];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setMentions:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
            
            if ([[self mentions] count] == 0) {
                [self goMakeFriends];
            }
            
            [[self tableView] reloadData];
            
            [[self refreshControl] endRefreshing];
            
            [[ActivityManager sharedManager] decrementActivityCount];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
        
        [[self activityIndicator] stopAnimating];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
    }];
}

-(void)goMakeFriends
{
    UIAlertView *mentionsError = [[UIAlertView alloc] initWithTitle:@"No mentions!" message:@"Man, you need to make some friends!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    [mentionsError show];
}

-(void)switchToSelectedUser:(NSNotification *)aNotification
{
    if ([kAppDelegate currentViewController] == self) {
        
        
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
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self mentions][[indexPathOfTappedRow row]][@"sender_user_id"]]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
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

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}


- (void)handleURL:(NSURL*)url
{
    
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[url absoluteString]];
    
    [webViewController setBarsTintColor:[UIColor darkGrayColor]];
    
    [self presentViewController:webViewController animated:YES completion:nil];
}

-(void)requestWithUsername:(NSString *)username
{
    if ([kAppDelegate currentViewController] == self) {
        
        
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
                [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
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

-(void)didReceiveMemoryWarning
{
    [[self externalImageCache] removeAllObjects];
    
    [super didReceiveMemoryWarning];
}

@end
