//
//  UsersWhoLikedViewController.m
//  Jukaela
//
//  Created by Josh on 1/1/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "ShowUserViewController.h"
#import "UsersPostsViewController.h"
#import "UsersWhoLikedViewController.h"

@interface UsersWhoLikedViewController ()
@property (strong, nonatomic) NSDictionary *tempDict;
@property (strong, nonatomic) NSMutableArray *tempArray;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation UsersWhoLikedViewController

-(id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
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
        
    [[self navigationController] setToolbarHidden:NO animated:YES];
    
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf)]];
            
    [[self collectionView] setBackgroundColor:[UIColor clearColor]];
    
    [[self view] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
}

-(void)dismissSelf
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:kShowUser]) {
        ShowUserViewController *viewController = [segue destinationViewController];
        
        [viewController setUserDict:_tempDict];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserPosts"]) {
        UsersPostsViewController *viewController = [segue destinationViewController];
        
        [viewController setUserPostArray:[self tempArray]];
    }
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [[self usersArray] count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UsersCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"UsersCell" forIndexPath:indexPath];
    
    [[cell textLabel] setText:[self usersArray][[indexPath row]][kName]];
    
    if ([self usersArray][[indexPath row]][kUsername] && [self usersArray][[indexPath row]][kUsername] != [NSNull null]) {
        [[cell usernameLabel] setText:[NSString stringWithFormat:@"@%@", [self usersArray][[indexPath row]][kUsername]]];
    }
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@-large.png", [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self usersArray][[indexPath row]][@"user_id"]]]]];
    
    if (image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[cell imageView] setImage:image];
            [cell setNeedsDisplay];
        });
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[NSString stringWithFormat:@"%@", [self usersArray][[indexPath row]][kEmail]] withSize:65]]];
            
#if (TARGET_IPHONE_SIMULATOR)
            image = [UIImage normalize:image];
#endif
            UIImage *resizedImage = [image thumbnailImage:65 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[cell imageView] setImage:resizedImage];
                [cell setNeedsDisplay];
                
                [UIImage saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@-large", [self usersArray][[indexPath row]][@"user_id"]]];
            });
        });
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithWindow:[[self view] window]];
    [progressHUD setMode:MBProgressHUDModeIndeterminate];
    [progressHUD setLabelText:@"Loading User..."];
    [progressHUD setDelegate:self];
    
    [[[self view] window] addSubview:progressHUD];
    
    [progressHUD show:YES];
    
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self usersArray][[indexPath row]][@"user_id"]]];
    
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
        
        [progressHUD hide:YES];
        
        [self performSegueWithIdentifier:kShowUser sender:nil];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Deselected item");
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(85, 97);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

@end
