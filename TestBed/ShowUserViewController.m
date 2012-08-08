//
//  ShowUserViewController
//  Jukaela Social
//
//  Created by Josh Barrow on 07/19/2012.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import "FollowerViewController.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "ShowUserViewController.h"
#import "UsersPostsViewController.h"

@implementation ShowUserViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf:)]];        
    
    [[self navigationItem] setTitle:@"Show User"];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    [self setFollowers:nil];
    [self setFollowing:nil];
    [self setPosts:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self getFollowers];
        [self getFollowing];
        [self getPosts];
    });
}

-(void)dismissSelf:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    
    if (section == 1) {
        return 1;
    }
    
    if (section == 2) {
        return 1;
    }
    
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    if ([indexPath section] == 0) {
        return 100;
    }
    else if ([indexPath section] == 1) {
        return 100;
    }
    else {
        return 55;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *SegmentedCellIdentifier = @"SegmentedCell";
    
    PrettyGridTableViewCell *segmentedCell;
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.section) {
        case 0: {
            [cell prepareForTableView:tableView indexPath:indexPath];
            
            [[cell textLabel] setTextAlignment:NSTextAlignmentRight];
            [[cell textLabel] setText:[self userDict][@"name"]];
            [[cell detailTextLabel] setTextAlignment:NSTextAlignmentRight];
            
            if ([self userDict][@"username"] && [self userDict][@"username"] != [NSNull null]) {
                [[cell detailTextLabel] setText:[self userDict][@"username"]];
            }
            else {
                [[cell detailTextLabel] setText:@"No username"];
            }
            
            UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userDict][@"id"]]]]];
            
            if (image) {
                [[cell imageView] setImage:image];
            } 
            else { 
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
                
                dispatch_async(queue, ^{            
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userDict][@"email"]]]];
                    
#if (TARGET_IPHONE_SIMULATOR)
                    image = [JEImages normalize:image];
#endif
                    UIImage *resizedImage = [image thumbnailImage:55 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[cell imageView] setImage:resizedImage];
                        [self saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self userDict][@"id"]]];      
                    });
                });
            }
        }
            break;
        case 1: {
            [cell prepareForTableView:tableView indexPath:indexPath];
            
            [[cell detailTextLabel] setNumberOfLines:5];
            
            if ([self userDict][@"profile"] && [self userDict][@"profile"] != [NSNull null] ) {
                [[cell detailTextLabel] setText:[self userDict][@"profile"]];
            }
            else {
                [[cell detailTextLabel] setText:@"No user profile"];
            }
            
            return cell;
        }
        case 2: {
            segmentedCell = [tableView dequeueReusableCellWithIdentifier:SegmentedCellIdentifier];
            
            if (segmentedCell == nil) {
                segmentedCell = [[PrettySegmentedControlTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SegmentedCellIdentifier];
            }
            
            __weak PrettyGridTableViewCell *tempSegContCell = segmentedCell;
            
            [segmentedCell prepareForTableView:tableView indexPath:indexPath];
            
            [segmentedCell setNumberOfElements:3];
            
            [segmentedCell setText:[NSString stringWithFormat:@"%i", [[self following] count]] atIndex:0];
            [segmentedCell setDetailText:@"Following" atIndex:0];
                        
            [segmentedCell setText:[NSString stringWithFormat:@"%i", [[self followers] count]] atIndex:1];
            [segmentedCell setDetailText:@"Followers" atIndex:1];
            
            [segmentedCell setText:[NSString stringWithFormat:@"%i", [[self posts] count]] atIndex:2];
            [segmentedCell setDetailText:@"Posts" atIndex:2];
                        
            [segmentedCell setActionBlock:^(NSIndexPath *indexPath, int selectedIndex) {
                if (selectedIndex == 0) {    
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self performSegueWithIdentifier:@"ShowFollowing" sender:nil];
                } 
                else if (selectedIndex == 1) {
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self performSegueWithIdentifier:@"ShowFollowers" sender:nil];
                }
                else if (selectedIndex == 2) {
                    [tempSegContCell deselectAnimated:YES];
                    
                    [self performSegueWithIdentifier:@"ShowUserPosts" sender:nil];
                }
            }];
        }
            return segmentedCell;
            break;
        default:
            break;
    }
    
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowFollowers"]) {
        PrettySegmentedControlTableViewCell *tempCell = (PrettySegmentedControlTableViewCell *)[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        [tempCell deselectAnimated:YES];
        
        FollowerViewController *viewController = [segue destinationViewController];
        
        [viewController setUsersArray:[self followers]];
        [viewController setTitle:@"Followers"];
    }
    else if ([[segue identifier] isEqualToString:@"ShowFollowing"]) {
        PrettySegmentedControlTableViewCell *tempCell = (PrettySegmentedControlTableViewCell *)[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]];
        
        [tempCell deselectAnimated:YES];
        
        FollowerViewController *viewController = [segue destinationViewController];
        
        [viewController setUsersArray:[self following]];
        [viewController setTitle:@"Following"];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserPosts"]) {
        UsersPostsViewController *viewController = [segue destinationViewController];
        
        [viewController setUserID:[self userDict][@"id"]];
        [viewController setUserPostArray:[self posts]];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)saveImage:(UIImage *)image withFileName:(NSString *)emailAddress
{
    if (image != nil)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths[0];
        NSString* path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithString:[NSString stringWithFormat:@"%@.png", emailAddress]]];
        NSData* data = UIImagePNGRepresentation(image);
        [data writeToFile:path atomically:YES];
    }
}

-(NSString *)documentsPath
{
    NSArray *tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = tempArray[0];
    
    return documentsDirectory;
}

-(void)getPosts
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userDict][@"id"]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self setPosts:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
                        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]; 
}

-(void)getFollowing
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/following.json", kSocialURL, [self userDict][@"id"]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
        [self setFollowing:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
                
        [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

-(void)getFollowers
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/followers.json", kSocialURL, [self userDict][@"id"]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [self setFollowers:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
                
        [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

@end
