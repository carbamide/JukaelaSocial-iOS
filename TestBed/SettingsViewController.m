//
//  SettingsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

-(void)customizeNavigationBar
{
    PrettyNavigationBar *navBar = (PrettyNavigationBar *)self.navigationController.navigationBar;
    
    [navBar setTopLineColor:[UIColor colorWithHex:0xafafaf]];
    [navBar setGradientStartColor:[UIColor colorWithHex:0x969696]];
    [navBar setGradientEndColor:[UIColor colorWithHex:0x3e3e3e]];
    [navBar setBottomLineColor:[UIColor colorWithHex:0x303030]];
    [navBar setTintColor:[navBar gradientEndColor]];
}

-(void)logOut:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"read_username_from_defaults"];
    
    [[[[self tabBarController] viewControllers] objectAtIndex:0] popToRootViewControllerAnimated:NO];
    
    [[self tabBarController] setSelectedIndex:0];
    
    [[[[[self tabBarController] tabBar] items] objectAtIndex:1] setEnabled:NO];
    [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setEnabled:NO];
}

-(id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)viewDidLoad
{
    [self customizeNavigationBar];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];  

    [super viewDidLoad];
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
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell setTableViewBackgroundColor:[tableView backgroundColor]];
    }
    
    [cell prepareForTableView:tableView indexPath:indexPath];

    if ([indexPath row] == 0) {
        [[cell textLabel] setText:@"Logout"];
    }
    else if ([indexPath row] == 1) {
        [[cell textLabel] setText:@"Clear Image Cache"];
    }
    
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath row]) {
        case 0:
            [self logOut:nil];
            break;
        case 1:
            [self clearImageCache];
            break;
        default:
            break;
    }
}

-(void)clearImageCache
{
    RIButtonItem *eraseButton = [RIButtonItem itemWithLabel:@"Clear Cache"];
    RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:@"Cancel"];
    
    [eraseButton setAction:^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            NSError *error = nil;  
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSString *directory = [paths objectAtIndex:0];
            
            for (NSString *file in [fileManager contentsOfDirectoryAtPath:directory error:&error]) {    
                NSString *filePath = [directory stringByAppendingPathComponent:file];
                
                BOOL fileDeleted = [fileManager removeItemAtPath:filePath error:&error];
                
                if (fileDeleted != YES || error != nil) {
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                         message:@"There has been an error.  Please reinstall Jukaela Social." 
                                                                        delegate:nil 
                                                               cancelButtonTitle:@"OK" 
                                                               otherButtonTitles:nil, nil];
                    
                    [errorAlert show];
                }
            }
        }
    }];
    
    [cancelButton setAction:^{
        return; 
    }];
    
    UIActionSheet *eraseAction = [[UIActionSheet alloc] initWithTitle:nil 
                                                     cancelButtonItem:cancelButton 
                                                destructiveButtonItem:eraseButton 
                                                     otherButtonItems:nil, nil];
    
    [eraseAction showFromTabBar:[[self tabBarController] tabBar]];
}

@end
