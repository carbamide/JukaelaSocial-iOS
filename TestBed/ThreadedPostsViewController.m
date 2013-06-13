//
//  ThreadedPostsViewController.m
//  Jukaela
//
//  Created by Josh on 12/26/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "NSDate+RailsDateParser.h"
#import "ThreadedPostsViewController.h"
#import "NormalCellView.h"
#import "NormalWithImageCellView.h"
#import "PostViewController.h"
#import "ShareObject.h"
#import "ShowUserViewController.h"
#import "SORelativeDateTransformer.h"
#import "SVModalWebViewController.h"
#import "WBSuccessNoticeView.h"
#import "WBErrorNoticeView.h"

@interface ThreadedPostsViewController ()
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@end

@implementation ThreadedPostsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [[self navigationController] setToolbarHidden:YES animated:YES];

    [kAppDelegate setCurrentViewController:self];
        
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [[self navigationController] setToolbarHidden:YES animated:NO];

    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf)]];
    
    NSLog(@"%@", [self threadedPosts]);
    
    [self setExternalImageCache:[[NSCache alloc] init]];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
        
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToSelectedUser:) name:kSendToUserNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLoadUserWithUsernameNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        NSString *usernameString = [aNotification userInfo][@"username"];
        
        [self requestWithUsername:usernameString];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kShowImage object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
       // [self showImage:aNotification];
    }];
    
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
    NSString *contentText = [self threadedPosts][[indexPath row]][kContent];
    
    CGSize constraint = CGSizeMake(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 750 : 300, 20000);
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    if ([self threadedPosts][[indexPath row]][kRepostUserID] && [self threadedPosts][[indexPath row]][kRepostUserID] != [NSNull null]) {
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
    return [[self threadedPosts] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FeedViewCell";
    static NSString *CellWithImageCellIdentifier = @"CellWithImageCellIdentifier";
    
    id cell = nil;
    
    if ([self threadedPosts][[indexPath row]][kImageURL] && [self threadedPosts][[indexPath row]][kImageURL] != [NSNull null]) {
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
    
    if ([self threadedPosts][[indexPath row]][kImageURL] && [self threadedPosts][[indexPath row]][kImageURL] != [NSNull null]) {
        NSMutableString *tempString = [NSMutableString stringWithString:[self threadedPosts][[indexPath row]][kImageURL]];
        
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
    
    [[cell contentText] setFontName:kFontPreference];
    [[cell contentText] setFontSize:17];
    
    if ([self threadedPosts][[indexPath row]][kContent]) {
        [[cell contentText] setText:[self threadedPosts][[indexPath row]][kContent]];
    }
    else {
        [[cell contentText] setText:@"Loading..."];
    }
    
    if ([self threadedPosts][[indexPath row]][kName] && [self threadedPosts][[indexPath row]][kName] != [NSNull null]) {
        [[cell nameLabel] setText:[self threadedPosts][[indexPath row]][kName]];
    }
    
    if ([self threadedPosts][[indexPath row]][kUsername] && [self threadedPosts][[indexPath row]][kUsername] != [NSNull null]) {
        [[cell usernameLabel] setText:[NSString stringWithFormat:@"@%@", [self threadedPosts][[indexPath row]][kUsername]]];
    }
    
    if ([self threadedPosts][[indexPath row]][kRepostUserID] && [self threadedPosts][[indexPath row]][kRepostUserID] != [NSNull null]) {
        CGSize contentSize = [[self threadedPosts][[indexPath row]][kContent] sizeWithFont:[UIFont systemFontOfSize:17]
                                                                         constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                             lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize nameSize = [[self threadedPosts][[indexPath row]][kName] sizeWithFont:[UIFont systemFontOfSize:14]
                                                                   constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                       lineBreakMode:NSLineBreakByWordWrapping];
        
        CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 75);
        
        if ([[NSString stringWithFormat:@"%@", [self threadedPosts][[indexPath row]][kUserID]] isEqualToString:[kAppDelegate userID]]) {
            [[cell repostedNameLabel] setFrame:CGRectMake(12, height, 228, 20)];
        }
        else {
            [[cell repostedNameLabel] setFrame:CGRectMake(86, height, 228, 20)];
        }
        [[cell repostedNameLabel] setText:[NSString stringWithFormat:@"Reposted by %@", [self threadedPosts][[indexPath row]][kRepostName]]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self threadedPosts][[indexPath row]][kCreationDate] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self threadedPosts][[indexPath row]][kUserID]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self threadedPosts][[indexPath row]][kUserID]]]] error:nil];
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetween:[NSDate date] and:attributes[NSFileCreationDate]] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self threadedPosts][[indexPath row]][kEmail] withSize:40]]];
                    
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
                        
                        [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self threadedPosts][[indexPath row]][kUserID]]];
                    });
                });
            }
        }
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self threadedPosts][[indexPath row]][kEmail] withSize:40]]];
            
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
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self threadedPosts][[indexPath row]][kUserID]]];
            });
        });
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:kShowUser]) {
        ShowUserViewController *viewController = [segue destinationViewController];
        
        [viewController setUserDict:_tempDict];
    }
    else if ([[segue identifier] isEqualToString:kShowReplyView]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [self threadedPosts][[[self tempIndexPath] row]][kUsername]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowRepostView]) {
        UITableViewCell *tempCell = [[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setRepostString:[NSString stringWithFormat:@"%@", [[tempCell textLabel] text]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == ([[self threadedPosts] count] - 1)) {
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userID]]];
        
        NSString *requestString = [RequestFactory feedRequestFrom:[[self threadedPosts] count] to:[[self threadedPosts] count] + 20];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                NSMutableArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                NSInteger oldTableViewCount = [[self threadedPosts] count];
                
                [[self threadedPosts] addObjectsFromArray:tempArray];
                
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

- (void)handleURL:(NSURL*)url
{
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[url absoluteString]];
    
    [webViewController setBarsTintColor:[UIColor darkGrayColor]];
    
    [self presentViewController:webViewController animated:YES completion:nil];
}

-(void)requestWithUsername:(NSString *)username
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
            
            [[self progressHUD] hide:YES];
            
            [self performSegueWithIdentifier:kShowUser sender:nil];
        }];
    }
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
        
        NSURL *url = nil;
        
        if ([self threadedPosts][[indexPathOfTappedRow row]][kOriginalPosterID] && [self threadedPosts][[indexPathOfTappedRow row]][kOriginalPosterID] != [NSNull null]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self threadedPosts][[indexPathOfTappedRow row]][kOriginalPosterID]]];
        }
        else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self threadedPosts][[indexPathOfTappedRow row]][kUserID]]];
        }
        
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

-(void)didReceiveMemoryWarning
{
    [[self externalImageCache] removeAllObjects];
    
    [super didReceiveMemoryWarning];
}

-(void)dismissSelf
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
