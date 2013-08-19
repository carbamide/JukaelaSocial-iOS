//
//  FeedViewController.m
//  Jukaela Social
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import "FeedViewController.h"
#import "ShowUserViewController.h"
#import "PhotoViewerViewController.h"
#import "PostViewController.h"
#import "ThreadedPostsViewController.h"
#import "UsersWhoLikedViewController.h"

@interface FeedViewController ()
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) NSIndexPath *tempIndexPath;
@property (strong, nonatomic) NSMutableArray *tempArray;
@property (strong, nonatomic) NSString *documentsFolder;
@property (strong, nonatomic) UIImage *tempImage;

@property (strong, nonatomic) MBProgressHUD *progressHUD;

@property (nonatomic) enum ChangeType currentChangeType;

@property (nonatomic) BOOL fbSuccess;
@property (nonatomic) BOOL jukaelaSuccess;
@property (nonatomic) BOOL justToJukaela;
@property (nonatomic) BOOL twitterSuccess;

-(void)refreshTableInformation:(NSInteger)from to:(NSInteger)to;

@end

@implementation FeedViewController

#pragma mark Lifecycle

-(id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];
    
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setExternalImageCache:[[NSCache alloc] init]];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    [refreshControl setTintColor:[UIColor blackColor]];
    [refreshControl addTarget:self action:@selector(refreshControlHandler:) forControlEvents:UIControlEventValueChanged];
    
    [self setRefreshControl:refreshControl];
    
    [self setDocumentsFolder:[Helpers documentsPath]];
    
    [self setupNotifications];
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composePost:)];
    
    [[self navigationItem] setRightBarButtonItem:composeButton];
    [[self navigationItem] setHidesBackButton:YES];
    
    [self setCurrentChangeType:-1];
    
    if ([self loadedDirectly] && [[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference] == YES) {
        [[ActivityManager sharedManager] incrementActivityCount];
        
        [[ApiFactory sharedManager] login];
    }
    else {
        if (![self tableDataSource]) {
            [self refreshTableInformation:0 to:20];
        }
    }
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)didReceiveMemoryWarning
{
    [[self externalImageCache] removeAllObjects];
    
    [super didReceiveMemoryWarning];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:kShowUser]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ShowUserViewController *viewController = (ShowUserViewController *)[navigationController topViewController];
        
        [viewController setUserDict:_tempDict];
    }
    else if ([[segue identifier] isEqualToString:kShowPostView]) {
        UINavigationController *navigationController = [segue destinationViewController];
        PostViewController *viewController = (PostViewController *)[navigationController topViewController];
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:[[self view] frame]];
        
        UIImage *tempImage = [self imageWithView:[self view]];
        
        [tempImageView setImage:tempImage];
        
        [[viewController view] insertSubview:tempImageView belowSubview:[viewController backgroundView]];
        
        if ([self tempImage]) {
            [viewController setImageFromExternalSource:[self tempImage]];
        }
        
        [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowReplyView]) {
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:[[self view] frame]];
        
        UIImage *tempImage = [self imageWithView:[self view]];
        
        [tempImageView setImage:tempImage];
        
        [[viewController view] insertSubview:tempImageView belowSubview:[viewController backgroundView]];
        
        FeedItem *feedItem = [self tableDataSource][[[self tempIndexPath] row]];
        
        [viewController setReplyString:[NSString stringWithFormat:@"@%@", [[feedItem user] username]]];
        [viewController setInReplyTo:[feedItem postId]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowRepostView]) {
        UITableViewCell *tempCell = [[self tableView] cellForRowAtIndexPath:[self tempIndexPath]];
        
        PostViewController *viewController = (PostViewController *)[[[segue destinationViewController] viewControllers] lastObject];
        
        [viewController setRepostString:[NSString stringWithFormat:@"%@", [[tempCell textLabel] text]]];
        
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
    }
    else if ([[segue identifier] isEqualToString:kShowThread]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ThreadedPostsViewController *viewController = (ThreadedPostsViewController *)[navigationController topViewController];
        
        [viewController setTableDataSource:[self tempArray]];
    }
    else if ([[segue identifier] isEqualToString:@"UsersWhoLiked"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        UsersWhoLikedViewController *viewController = (UsersWhoLikedViewController *)[navigationController topViewController];
        
        [viewController setUsersArray:[self tempArray]];
    }
}

#pragma mark Init helpers
-(void)initializeActivityIndicator
{
    if (![self activityIndicator]) {
        [self setActivityIndicator:[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)]];
        
        [[self activityIndicator] setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    }
    
    if (![[self activityIndicator] isAnimating]) {
        [[self activityIndicator] startAnimating];
    }
}

-(void)setupNotifications
{
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapHandler:) name:kTapNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tappedUserHandler:) name:kSendToUserNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"show_image_opener" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self showImageOpener:aNotification];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"deleted_post" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [[[self tableView] cellForRowAtIndexPath:[self tempIndexPath]] setSelected:NO animated:YES];
        
        [self setCurrentChangeType:DELETE_POST];
        
        [self refreshTableInformation:0 to:[[self tableDataSource] count]];
        
        [[ActivityManager sharedManager] decrementActivityCount];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"thread_for_micropost" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self setTempArray:[aNotification userInfo][@"thread"]];
        
        [self performSegueWithIdentifier:kShowThread sender:self];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"liked_post" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification){
        [self refreshControlHandler:nil];
        
        [[ActivityManager sharedManager] decrementActivityCount];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kChangeTypeNotification object:nil queue:mainQueue usingBlock:^(NSNotification *number) {
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
            NSLog(@"Some kind of madness has happened");
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kRefreshYourTablesNotification object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self initializeActivityIndicator];
        
        [[self externalImageCache] removeAllObjects];
        
        [self refreshTableInformation:0 to:[[self tableDataSource] count]];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSuccessfulTweetNotification object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setTwitterSuccess:YES];
        
        [[self externalImageCache] removeAllObjects];
        
        [self checkForFBAndTwitterSucess];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSuccessfulFacebookNotification object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setFbSuccess:YES];
        
        [[self externalImageCache] removeAllObjects];
        
        [self checkForFBAndTwitterSucess];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kFacebookOrTwitterCurrentlySending object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self initializeActivityIndicator];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kStopAnimatingActivityIndicator object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        if ([[self activityIndicator] isAnimating]) {
            [[self activityIndicator] stopAnimating];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPostOnlyToJukaela object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self setJustToJukaela:YES];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kShowImage object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        [self showImageHandler:aNotification];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPostImage object:nil queue:mainQueue usingBlock:^(NSNotification *aNotification) {
        UIImage *temp = [aNotification userInfo][kImageNotification];
        
        [self setTempImage:temp];
        
        [self performSegueWithIdentifier:kShowPostView sender:self];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLoadUserWithUsernameNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        NSString *usernameString = [aNotification userInfo][@"username"];
        
        [self requestWithUsername:usernameString];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"logged_in" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        User *tempUser = [aNotification userInfo][@"loginUser"];
        
        [self loginHandler:tempUser];
    }];
}

-(void)checkForFBAndTwitterSucess
{
    if (([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) && ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference] == NO)) {
        if ([self twitterSuccess]) {
            [self setTwitterSuccess:NO];
            
            [[self activityIndicator] stopAnimating];
        }
    }
    else if (([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) && ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference] == NO)) {
        if ([self fbSuccess]) {
            [self setFbSuccess:NO];
            
            [[self activityIndicator] stopAnimating];
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference] && [[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
        if ([self twitterSuccess] && [self fbSuccess]) {
            [self setTwitterSuccess:NO];
            [self setFbSuccess:NO];
            
            [[self activityIndicator] stopAnimating];
        }
    }
    else {
        return;
    }
}

-(void)composePost:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:kShowPostView sender:self];
}

#pragma mark Handlers
- (void)insertPostHandler:(NSInteger)difference to:(NSInteger)to
{
    if ([self justToJukaela]) {
        [[self activityIndicator] stopAnimating];
        
        [self setJustToJukaela:NO];
    }
    
    @try {
        [[self tableView] beginUpdates];
        
        if (difference > 2) {
            difference /= 2;
        }
        else if (difference == 2) {
            difference = 1;
        }
        
        for (int i = 0; i < difference; i++) {
            [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            
            [[self tableView] deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:(to - 1) - i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [[self tableView] endUpdates];
    }
    @catch (NSException *exception) {
        if (exception) {
            NSLog(@"%@", exception);
            NSLog(@"Crazy things just happened with the integrity of this table, yo");
        }
        
        UIAlertView *tableError = [[UIAlertView alloc] initWithTitle:@"Table Integrity Issue!" message:[NSString stringWithFormat:@"Table has been restored.  Error %i", difference] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [tableError show];
        
        [self setCurrentChangeType:-1];
        
        [self setTableDataSource:nil];
        
        [self refreshTableInformation:0 to:20];
    }
    @finally {
        NSLog(@"Inside finally");
    }
}

- (void)deletePostHandler:(NSIndexPath *)indexPath
{
    @try {
        [[self tableView] beginUpdates];
        [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:19 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        
        [[self tableView] endUpdates];
    }
    @catch (NSException *exception) {
        if (exception) {
            NSLog(@"%@", exception);
            NSLog(@"Crazy things just happened with the integrity of this table, yo");
            
            [self setCurrentChangeType:-1];
            
            [self setTableDataSource:nil];
            
            [self refreshTableInformation:0 to:20];
        }
    }
    @finally {
        NSLog(@"Inside finally");
    }
}

-(void)loginHandler:(User *)tempUser
{
    if (tempUser) {
        for (UITabBarItem *item in [[[self tabBarController] tabBar] items]) {
            [item setEnabled:YES];
        }
        
        [kAppDelegate setUserID:[tempUser userId]];
        [kAppDelegate setUserEmail:[NSString stringWithFormat:@"%@", [tempUser email]]];
        [kAppDelegate setUserUsername:[NSString stringWithFormat:@"%@", [tempUser username]]];
        
        [[NSUserDefaults standardUserDefaults] setValue:[kAppDelegate userID] forKey:kUserID];
        
        [[self progressHUD] setLabelText:@"Loading Feed..."];
        
        [self refreshTableInformation:0 to:20];
    }
    else {
        [[self progressHUD] hide:YES];
        
        UIAlertView *loginFailedAlert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Your login has failed." cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:^{
            [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
        }]
                                                          otherButtonItems:nil, nil];
        
        [loginFailedAlert show];
    }
    
    [[ActivityManager sharedManager] decrementActivityCount];
    
}

- (void)feedHandler:(NSNotification *)aNotification to:(NSInteger)to
{
    NSArray *tempArray = [aNotification userInfo][@"feed"];
    
    NSArray *oldArray = [self tableDataSource];
    
    [self setTableDataSource:[tempArray mutableCopy]];
    
    NSMutableSet *firstSet = [NSMutableSet setWithArray:[self tableDataSource]];
    NSMutableSet *secondSet = [NSMutableSet setWithArray:[self tableDataSource]];
    
    [firstSet unionSet:[NSSet setWithArray:oldArray]];
    [secondSet intersectSet:[NSSet setWithArray:oldArray]];
    
    [firstSet minusSet:secondSet];
    
    NSInteger difference = [firstSet count];
    
    if ([self currentChangeType] == INSERT_POST) {
        [self insertPostHandler:difference to:to];
    }
    else if ([self currentChangeType] == DELETE_POST) {
        [self deletePostHandler:[self tempIndexPath]];
    }
    else {
        if ([[self activityIndicator] isAnimating]) {
            [[self activityIndicator] stopAnimating];
        }
        
        [[self tableView] reloadData];
    }
    
    [self setCurrentChangeType:-1];
    
    [[ActivityManager sharedManager] decrementActivityCount];
    
    [[self refreshControl] endRefreshing];
    
    if (![[self progressHUD] isHidden]) {
        [[self progressHUD] hide:YES];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
}

-(void)refreshControlHandler:(id)sender
{
    [self refreshTableInformation:0 to:([[self tableDataSource] count] - 1)];
}

#pragma mark Refresh Table
-(void)refreshTableInformation:(NSInteger)from to:(NSInteger)to
{
    if (!from) {
        from = 0;
    }
    
    if (!to) {
        to = 20;
    }
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    [[ApiFactory sharedManager] getFeedFrom:from to:to];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kLoadedFeed object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self feedHandler:aNotification to:to];
    }];
}


#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FeedItem *feedItem = [self tableDataSource][[indexPath row]];
    
    CGSize constraint = CGSizeMake(300, 20000);
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIColor *color = [UIColor blackColor];
    
    NSDictionary *attrDict = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[feedItem content] attributes:attrDict];
    
    CGRect rect = [string boundingRectWithSize:constraint options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    
    if ([feedItem repostUserId]) {
        return rect.size.height + 50 + 10 + 20;
    }
    else {
        return rect.size.height + 50 + 10;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self tableDataSource] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FeedItem *feedItem = [self tableDataSource][[indexPath row]];
    
    static NSString *CellIdentifier = @"FeedViewCell";
    static NSString *CellWithImageCellIdentifier = @"CellWithImageCellIdentifier";
    
    id cell = nil;
    
    if ([feedItem imageUrl]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellWithImageCellIdentifier];
        
        if (!cell) {
            cell = [[NormalWithImageCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellWithImageCellIdentifier withTableView:tableView withImageCache:[self externalImageCache] withIndexPath:(NSIndexPath *)indexPath];
            
            [cell setBackgroundView:[[CellBackground alloc] init]];
        }
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (!cell) {
            cell = [[NormalCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier withTableView:tableView];
            
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
    else {
        if ([[feedItem user] userId]) {
            [[cell nameLabel] setText:[NSString stringWithFormat:@"%@", [self nameDict][[[feedItem user] userId]]]];
        }
        else {
            [[cell nameLabel] setText:@"Loading..."];
        }
    }
    
    if ([[feedItem user] username]) {
        [[cell usernameLabel] setText:[NSString stringWithFormat:@"@%@", [[feedItem user] username]]];
    }
    
    if ([feedItem repostUserId]) {
        [[cell repostedNameLabel] setUserInteractionEnabled:YES];
        
        CGSize contentSize;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([feedItem imageUrl]) {
            contentSize = [[feedItem content] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                         constrainedToSize:CGSizeMake(185 - (7.5 * 2), 20000)
                                             lineBreakMode:NSLineBreakByWordWrapping];
        }
        else {
            contentSize = [[feedItem content] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                         constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                             lineBreakMode:NSLineBreakByWordWrapping];
        }
        CGSize nameSize = [[[feedItem user] name] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
                                             constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                 lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
        
        CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 85);
        
        [[cell repostedNameLabel] setFrame:CGRectMake(7, height - 5, 228, 20)];
        
        [[cell repostedNameLabel] setText:[NSString stringWithFormat:@"Reposted by %@", [feedItem repostName]]];
    }
    else {
        [[cell repostedNameLabel] setUserInteractionEnabled:NO];
    }
    
    [cell setDate:[feedItem createdAt]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[self documentsFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]]] error:nil];
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetween:[NSDate date] and:attributes[NSFileCreationDate]] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[[feedItem user] email] withSize:40]]];
                    
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
                        
                        [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]];
                    });
                });
            }
        }
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[[feedItem user] email] withSize:40]]];
            
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
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]];
            });
        });
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == ([[self tableDataSource] count] - 1)) {
        [[ActivityManager sharedManager] incrementActivityCount];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
        
        NSString *requestString = [RequestFactory feedRequestFrom:[[self tableDataSource] count] to:[[self tableDataSource] count] + 20];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
        
        [self initializeActivityIndicator];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                NSMutableArray *tempArray = [[ObjectMapper convertToFeedItemArray:data] mutableCopy];
                
                NSInteger oldTableViewCount = [[self tableDataSource] count];
                
                NSMutableArray *rehashOfOldArray = [NSMutableArray arrayWithArray:[self tableDataSource]];
                
                [rehashOfOldArray addObjectsFromArray:tempArray];
                
                [self setTableDataSource:rehashOfOldArray];
                
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
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kEnableCellNotification object:nil];
        }];
        [[ActivityManager sharedManager] decrementActivityCount];
    }
}

#pragma mark JukaelaTableView Protocol Methods

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

@end
