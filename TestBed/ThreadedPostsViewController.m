//
//  ThreadedPostsViewController
//  Jukaela
//
//  Created by Josh on 12/26/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "ThreadedPostsViewController.h"
#import "ShowUserViewController.h"
#import "PhotoViewerViewController.h"
#import "PostViewController.h"

@interface ThreadedPostsViewController ()
@property (strong, nonatomic) NSArray *tempArray;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) NSDictionary *tempDict;
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
    [[NSNotificationCenter defaultCenter] addObserverForName:kShowImage object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self showImageHandler:aNotification];
    }];
    
    [[self navigationController] setToolbarHidden:YES animated:NO];

    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf)]];
        
    [self setExternalImageCache:[[NSCache alloc] init]];
            
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tappedUserHandler:) name:kSendToUserNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLoadUserWithUsernameNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        NSString *usernameString = [aNotification userInfo][@"username"];
        
        [self requestWithUsername:usernameString];
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
    FeedItem *feedItem = [self tableDataSource][[indexPath row]];
    
    NSString *contentText = [feedItem content];
    
    CGSize constraint = CGSizeMake(300, 20000);
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIColor *color = [UIColor blackColor];
    
    NSDictionary *attrDict = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:contentText attributes:attrDict];
    
    CGRect rect = [string boundingRectWithSize:constraint options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];

    return rect.size.height + 50 + 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self tableDataSource] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FeedViewCell";
    static NSString *CellWithImageCellIdentifier = @"CellWithImageCellIdentifier";
    
    id cell = nil;
    
    FeedItem *feedItem = [self tableDataSource][[indexPath row]];
    
    if ([feedItem imageUrl]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellWithImageCellIdentifier];
        
        if (!cell) {
            cell = [[NormalWithImageCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellWithImageCellIdentifier withTableView:tableView withImageCache:[self externalImageCache] withIndexPath:indexPath];
            
            [cell setBackgroundView:[[CellBackground alloc] init]];
        }
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (!cell) {
            cell = [[NormalCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier withTableView:tableView withIndexPath:indexPath];
            
            [cell setBackgroundView:[[CellBackground alloc] init]];
        }
    }
    
    if ([feedItem imageUrl]) {
        [cell setImageUrl:[feedItem imageUrl]];
    }
    
    if ([feedItem content]) {
        [[cell contentText] setText:[feedItem content]];
    }
    else {
        [[cell contentText] setText:@"Loading..."];
    }
    
    if ([[feedItem user] name]) {
        [[cell nameLabel] setText:[[feedItem user] name]];
    }
    
    if ([[feedItem user] username]) {
        [[cell usernameLabel] setText:[[feedItem user] username]];
    }
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:[feedItem createdAt]]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]]] error:nil];
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetweenDate:[NSDate date] andDate:attributes[NSFileCreationDate] options:0] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[[feedItem user] email] withSize:40]]];
                    
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
                        
                        [UIImage saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]];
                    });
                });
            }
        }
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[[feedItem user] email] withSize:40]]];
            
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
                
                [UIImage saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]];
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
        FeedItem *feedItem = [self tableDataSource][[[self tempIndexPath] row]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:[[self view] frame]];
        
        UIImage *tempImage = [self imageWithView:[self view]];
        
        [tempImageView setImage:tempImage];
        
        [[viewController view] insertSubview:tempImageView belowSubview:[viewController backgroundView]];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [[feedItem user] username]]];
        
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
        
        FeedItem *feedItem = [self tableDataSource][[indexPathOfTappedRow row]];
        
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = nil;
        
        if ([feedItem originalPosterId]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [feedItem originalPosterId]]];
        }
        else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [[feedItem user] userId]]];
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

-(void)tapHandler:(NSNotification *)aNotification
{
    RIButtonItem *likeButton = nil;
    RIButtonItem *usersWhoLiked = nil;
    RIButtonItem *replyButton = nil;
    RIButtonItem *showThread = nil;
    RIButtonItem *deleteThread = nil;
    RIButtonItem *cancelButton = nil;
    
    if ([kAppDelegate currentViewController] == self) {
        NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][kIndexPath];
        
        FeedItem *feedItem = [self tableDataSource][[indexPathOfTappedRow row]];
        
        [self setTempIndexPath:indexPathOfTappedRow];
        
        if (![[[feedItem user] userId] isEqualToNumber:[kAppDelegate userID]]) {
            BOOL addTheLikeButton = YES;
            
            if ([feedItem usersWhoLiked]) {
                for (NSDictionary *userWhoLiked in [feedItem usersWhoLiked]) {
                    if ([userWhoLiked[@"user_id"] isEqualToNumber:[kAppDelegate userID]]) {
                        addTheLikeButton = NO;
                    }
                }
            }
            
            if (addTheLikeButton) {
                likeButton = [RIButtonItem itemWithLabel:@"Like" action:^{
                    [[ActivityManager sharedManager] incrementActivityCount];
                    
                    [[ApiFactory sharedManager] likePost:[feedItem postId]];
                    
                    [[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow] setSelected:NO animated:YES];
                }];
            }
        }
        
        if ([feedItem usersWhoLiked] && (unsigned long)[[feedItem usersWhoLiked] count] > 0) {
            NSString *pluralization = nil;
            
            if ((unsigned long)[[feedItem usersWhoLiked] count] == 1) {
                pluralization = @"Like";
            }
            else if ((unsigned long)[[feedItem usersWhoLiked] count] > 1) {
                pluralization = @"Likes";
            }
            
            usersWhoLiked = [RIButtonItem itemWithLabel:[NSString stringWithFormat:@"%lu %@", (unsigned long)[[feedItem usersWhoLiked] count], pluralization] action:^{
                [self setTempArray:[[feedItem usersWhoLiked] mutableCopy]];
                
                [self performSegueWithIdentifier:@"UsersWhoLiked" sender:self];
            }];
        }
        
        replyButton = [RIButtonItem itemWithLabel:@"Reply" action:^{
            [self performSegueWithIdentifier:kShowReplyView sender:self];
        }];
        
        if ([feedItem inReplyTo]) {
            showThread = [RIButtonItem itemWithLabel:@"Show Thread" action:^{
                [[ApiFactory sharedManager] showThreadForPost:[feedItem postId]];
            }];
        }
        
        if ([[[feedItem user] userId] isEqualToNumber:[kAppDelegate userID]]) {
            deleteThread = [RIButtonItem itemWithLabel:@"Delete Post" action:^{
                [[ActivityManager sharedManager] incrementActivityCount];
                
                NormalCellView *tempCell = (NormalCellView *)[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow];
                
                [tempCell disableCell];
                
                [self setTempIndexPath:indexPathOfTappedRow];
                
                [[ApiFactory sharedManager] deletePost:[feedItem postId]];
            }];
        }
        
        cancelButton = [RIButtonItem itemWithLabel:@"Cancel" action:^{
            [[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow] setSelected:NO animated:YES];
            
            return;
        }];
        
        UIActionSheet *cellActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelButton destructiveButtonItem:deleteThread otherButtonItems:replyButton, likeButton, usersWhoLiked, showThread, nil];
        
        [cellActionSheet showInView:[self view]];
    }
}

-(void)showImageHandler:(NSNotification *)aNotification
{
    if ([kAppDelegate currentViewController] == self) {
        NSIndexPath *indexPath = [aNotification userInfo][kIndexPath];
        
        FeedItem *feedItem = [self tableDataSource][[indexPath row]];
        
        [[ApiFactory sharedManager] showImage:[feedItem imageUrl]];
        
    }
}

- (void)showImageOpener:(NSNotification *)aNotification
{
    NSData *data = [aNotification userInfo][@"data"];
    
    if (data) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        
        PhotoViewerViewController *viewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ShowPhotos"];
        
        [viewController setMainImage:[UIImage imageWithData:data]];
        
        UIImage *tempImage = [[self imageWithView:[self view]] applyBlurWithRadius:10 tintColor:[UIColor clearColor] saturationDeltaFactor:1.0 maskImage:nil];
        
        [viewController setBackgroundImage:tempImage];
        
        [self presentViewController:viewController animated:YES completion:nil];
    }
    else {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"There has been an error downloading the requested image."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil];
        
        [errorAlert show];
    }
}

-(void)tappedUserHandler:(NSNotification *)aNotification
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
        
        FeedItem *feedItem = [self tableDataSource][[indexPathOfTappedRow row]];
        
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = nil;
        
        if ([feedItem originalPosterId]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [feedItem originalPosterId]]];
        }
        else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [[feedItem user] userId]]];
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

@end
