//
//  FollowerViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import "NormalCellView.h"
#import "FollowerViewController.h"
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "ShowUserViewController.h"
#import "UsersPostsViewController.h"

@interface FollowerViewController ()
@property (strong, nonatomic) NSMutableArray *tempArray;
@property (strong, nonatomic) NSDictionary *tempDict;

@end

@implementation FollowerViewController

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doubleTap:) name:@"double_tap" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToSelectedUser:) name:@"send_to_user" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repostSwitchToSelectedUser:) name:@"repost_send_to_user" object:nil];
    
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"double_tap" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"send_to_user" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"repost_send_to_user" object:nil];
    
    [super viewDidDisappear:animated];
}

-(void)viewDidLoad
{
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    [super viewDidLoad];
}

-(void)switchToSelectedUser:(NSNotification *)aNotification
{
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:[self view]];
    [progressHUD setMode:MBProgressHUDModeIndeterminate];
    [progressHUD setLabelText:@"Loading User..."];
    [progressHUD setDelegate:self];
    
    [[self view] addSubview:progressHUD];
    
    [progressHUD show:YES];
    
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self usersArray][[indexPathOfTappedRow row]][@"id"]]];
    
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
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [progressHUD hide:YES];
        
        [self performSegueWithIdentifier:@"ShowUser" sender:nil];
    }];
}

-(void)repostSwitchToSelectedUser:(NSNotification *)aNotification
{
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:[self view]];
    [progressHUD setMode:MBProgressHUDModeIndeterminate];
    [progressHUD setLabelText:@"Loading User..."];
    [progressHUD setDelegate:self];
    
    [[self view] addSubview:progressHUD];
    
    [progressHUD show:YES];
    
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self usersArray][[indexPathOfTappedRow row]][@"repost_user_id"]]];
    
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
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [progressHUD hide:YES];
        
        [self performSegueWithIdentifier:@"ShowUser" sender:nil];
    }];
}

-(void)getUsers
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self setUsersArray:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[self tableView] reloadData];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading the user list.  Please logout and log back in."];
        }
    }];
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

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self usersArray] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FollowerViewCell";
    
    NormalCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[NormalCellView alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell setBackgroundView:[[CellBackground alloc] init]];
    }
    
    [[cell contentText] setFontName:@"Helvetica-Bold"];
    
    [[cell contentText] setText:[self usersArray][[indexPath row]][@"name"]];
    
    if ([self usersArray][[indexPath row]][@"username"] && [self usersArray][[indexPath row]][@"username"] != [NSNull null]) {
        [[cell detailTextLabel] setText:[self usersArray][[indexPath row]][@"username"]];
    }
    else {
        [[cell detailTextLabel] setText:@"No username specified"];
    }
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self usersArray][[indexPath row]][@"id"]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self usersArray][[indexPath row]][@"email"]]]] error:nil];
    
    if (image) {        
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetween:[NSDate date] and:attributes[NSFileCreationDate]] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[NSString stringWithFormat:@"%@", [self usersArray][[indexPath row]][@"email"]]]]];
                    
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
                        
                        [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self usersArray][[indexPath row]][@"id"]]];
                    });
                });
            }
        }
    }
    else {
		dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[NSString stringWithFormat:@"%@", [self usersArray][[indexPath row]][@"email"]]]]];
			
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
				
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self usersArray][[indexPath row]][@"id"]]];
			});
		});
	}
    
    return cell;
}
#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowUser"]) {
        ShowUserViewController *viewController = [segue destinationViewController];
        
        [viewController setUserDict:_tempDict];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserPosts"]) {
        UsersPostsViewController *viewController = [segue destinationViewController];
        
        [viewController setUserPostArray:[self tempArray]];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

-(void)doubleTap:(NSNotification *)aNotification
{
    NSIndexPath *indexPathOfTappedRow = (NSIndexPath *)[aNotification userInfo][@"indexPath"];
    
    BlockActionSheet *userActionSheet = [[BlockActionSheet alloc] initWithTitle:nil];
    
    [userActionSheet addButtonWithTitle:@"Show User" block:^{
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:[self view]];
        [progressHUD setMode:MBProgressHUDModeIndeterminate];
        [progressHUD setLabelText:@"Loading User..."];
        [progressHUD setDelegate:self];
        
        [[self view] addSubview:progressHUD];
        
        [progressHUD show:YES];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self usersArray][[indexPathOfTappedRow row]][@"id"]]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
                
                [[[self tableView] cellForRowAtIndexPath:indexPathOfTappedRow] setSelected:NO animated:YES];
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                [self performSegueWithIdentifier:@"ShowUser" sender:nil];
            }
            else {
                RIButtonItem *logoutButton = [RIButtonItem itemWithLabel:@"Logout"];
                RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:@"Cancel"];
                
                [logoutButton setAction:^{
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"read_username_from_defaults"];
                    
                    [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
                    
                    [[self tabBarController] setSelectedIndex:0];
                    
                    [[[[self tabBarController] tabBar] items][1] setEnabled:NO];
                    [[[[self tabBarController] tabBar] items][2] setEnabled:NO];
                    [[[[self tabBarController] tabBar] items][3] setEnabled:NO];
                }];
                
                [cancelButton setAction:^{
                    return;
                }];
                
                [Helpers errorAndLogout:self withMessage:@"There was an error showing the user.  Please logout and log back in."];
            }
            [progressHUD hide:YES];
        }];
    }];
    
    [userActionSheet setCancelButtonWithTitle:@"Cancel" block:nil];
    
    [userActionSheet showInView:[self view]];
}
@end
