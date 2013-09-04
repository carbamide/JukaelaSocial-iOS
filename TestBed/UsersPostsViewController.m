//
//  UsersPostsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/17/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "PostViewController.h"
#import "ShowUserViewController.h"
#import "UsersPostsViewController.h"


@interface UsersPostsViewController ()
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@end

@implementation UsersPostsViewController

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
    
    [[self navigationController] setToolbarHidden:YES animated:YES];

    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    if ([[self navigationController] viewControllers][0] != self) {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf)]];
    }
    
    [self setExternalImageCache:[[NSCache alloc] init]];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    [refreshControl setTintColor:[UIColor blackColor]];
    
    [refreshControl addTarget:self action:@selector(refreshTableInformation) forControlEvents:UIControlEventValueChanged];
    
    [self setRefreshControl:refreshControl];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    [self setTitle:[[self userPostArray] lastObject][kName]];
    
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToSelectedUser:) name:kSendToUserNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLoadUserWithUsernameNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        NSString *usernameString = [aNotification userInfo][@"username"];
        
        [self requestWithUsername:usernameString];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kShowImage object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        //[self showImage:aNotification];
    }];
    
    [super viewDidLoad];
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
    NSString *contentText = [self userPostArray][[indexPath row]][kContent];
    
    CGSize constraint = CGSizeMake(300, 20000);
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIColor *color = [UIColor blackColor];
    
    NSDictionary *attrDict = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:contentText attributes:attrDict];
    
    CGRect rect = [string boundingRectWithSize:constraint options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    
    if ([self userPostArray][[indexPath row]][kRepostUserID] && [self userPostArray][[indexPath row]][kRepostUserID] != [NSNull null]) {
        return rect.size.height + 50 + 10 + 20;
    }
    else {
        return rect.size.height + 50 + 10;
    }
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
    
    if ([self userPostArray][[indexPath row]][kImageURL] && [self userPostArray][[indexPath row]][kImageURL] != [NSNull null]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellWithImageCellIdentifier];
        
        if (!cell) {
            cell = [[NormalWithImageCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellWithImageCellIdentifier withTableView:tableView withIndexPath:indexPath];
            
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
    
    if ([self userPostArray][[indexPath row]][kImageURL] && [self userPostArray][[indexPath row]][kImageURL] != [NSNull null]) {
        NSMutableString *tempString = [NSMutableString stringWithString:[self userPostArray][[indexPath row]][kImageURL]];
        
        NSString *tempExtensionString = [NSString stringWithFormat:@".%@", [tempString pathExtension]];
        
        [tempString stringByReplacingOccurrencesOfString:tempExtensionString withString:@""];
        [tempString appendFormat:@"s"];
        [tempString appendString:tempExtensionString];
        
        if (![[cell externalImage] image]) {
            if ([[self externalImageCache] objectForKey:indexPath]) {
                [[cell externalImage] setImage:[[self externalImageCache] objectForKey:indexPath]];
            }
            else if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSString documentsPath] stringByAppendingPathComponent:[tempString lastPathComponent]]]) {
                UIImage *externalImageFromDisk = [UIImage imageWithData:[NSData dataWithContentsOfFile:[[NSString documentsPath] stringByAppendingPathComponent:[tempString lastPathComponent]]]];
                
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
                        
                        [UIImage saveImage:image withFileName:[tempString lastPathComponent]];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            NSString *path = [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithString:[tempString lastPathComponent]]];
                            
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
    
    if ([self userPostArray][[indexPath row]][kContent]) {
        [[cell contentText] setText:[self userPostArray][[indexPath row]][kContent]];
    }
    else {
        [[cell contentText] setText:@"Loading..."];
    }
    
    if ([self userPostArray][[indexPath row]][kName] && [self userPostArray][[indexPath row]][kName] != [NSNull null]) {
        [[cell nameLabel] setText:[self userPostArray][[indexPath row]][kName]];
    }
    
    if ([self userPostArray][[indexPath row]][kUsername] && [self userPostArray][[indexPath row]][kUsername] != [NSNull null]) {
        [[cell usernameLabel] setText:[NSString stringWithFormat:@"@%@", [self userPostArray][[indexPath row]][kUsername]]];
    }
    
    if ([self userPostArray][[indexPath row]][kRepostUserID] && [self userPostArray][[indexPath row]][kRepostUserID] != [NSNull null]) {
        CGSize contentSize = [[self userPostArray][[indexPath row]][kContent] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                                         constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                             lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize nameSize = [[self userPostArray][[indexPath row]][kName] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]
                                                                   constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                                       lineBreakMode:NSLineBreakByWordWrapping];
        
        CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 75);
        
        if ([[self userPostArray][[indexPath row]][kUserID] isEqualToNumber:[kAppDelegate userID]]) {
            [[cell repostedNameLabel] setFrame:CGRectMake(12, height, 228, 20)];
        }
        else {
            [[cell repostedNameLabel] setFrame:CGRectMake(86, height, 228, 20)];
        }
        [[cell repostedNameLabel] setText:[NSString stringWithFormat:@"Reposted by %@", [self userPostArray][[indexPath row]][kRepostName]]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self userPostArray][[indexPath row]][kCreationDate] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][kUserID]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][kUserID]]]] error:nil];
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetweenDate:[NSDate date] andDate:attributes[NSFileCreationDate] options:0] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userPostArray][[indexPath row]][kEmail] withSize:40]]];
                    
#if (TARGET_IPHONE_SIMULATOR)
                    image = [UIImage normalize:image];
#endif
                    UIImage *resizedImage = [image thumbnailImage:40 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
                        
                        if ([indexPath isEqual:cellIndexPath]) {
                            [[cell imageView] setImage:resizedImage];
                            [cell setNeedsDisplay];
                        }
                        
                        [UIImage saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][kUserID]]];
                    });
                });
            }
        }
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userPostArray][[indexPath row]][kEmail] withSize:40]]];
            
#if (TARGET_IPHONE_SIMULATOR)
            image = [UIImage normalize:image];
#endif
            UIImage *resizedImage = [image thumbnailImage:40 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
                
                if ([indexPath isEqual:cellIndexPath]) {
                    [[cell imageView] setImage:resizedImage];
                    [cell setNeedsDisplay];
                }
                
                [UIImage saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self userPostArray][[indexPath row]][kUserID]]];
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
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [self userPostArray][[[self tempIndexPath] row]][kUsername]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowRepostView]) {
        UITableViewCell *tempCell = [[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:[[self view] frame]];
        
        UIImage *tempImage = [self imageWithView:[self view]];
        
        [tempImageView setImage:tempImage];
        
        [[viewController view] insertSubview:tempImageView belowSubview:[viewController backgroundView]];
        
        [viewController setRepostString:[NSString stringWithFormat:@"%@", [[tempCell textLabel] text]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
}


-(void)refreshTableInformation
{
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userID]]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest getRequestWithURL:url timeout:60];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [self setUserPostArray:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
            
            [[self tableView] reloadData];
            
            [[self refreshControl] endRefreshing];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user's information.  Please logout and log back in."];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
    }];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == ([[self userPostArray] count] - 1)) {
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userID]]];
        
        NSString *requestString = [RequestFactory feedRequestFrom:[[self userPostArray] count] to:[[self userPostArray] count] + 20];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest postRequestWithURL:url withData:requestData timeout:60];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                [[ActivityManager sharedManager] decrementActivityCount];

                NSMutableArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                NSInteger oldTableViewCount = [[self userPostArray] count];
                
                [[self userPostArray] addObjectsFromArray:tempArray];
                
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
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
        }];
        [[ActivityManager sharedManager] decrementActivityCount];
    }
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
        
        NSMutableURLRequest *request = [NSMutableURLRequest postRequestWithURL:url withData:requestData timeout:60];
        
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
        
        if ([self userPostArray][[indexPathOfTappedRow row]][kOriginalPosterID] && [self userPostArray][[indexPathOfTappedRow row]][kOriginalPosterID] != [NSNull null]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self userPostArray][[indexPathOfTappedRow row]][kOriginalPosterID]]];
        }
        else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self userPostArray][[indexPathOfTappedRow row]][kUserID]]];
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
