//
//  SettingsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Accounts/Accounts.h>
#import "SettingsViewController.h"
#import "PrettyKit.h"
#ifdef __IPHONE_6_0
#import <Social/Social.h>
#endif
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
    
    [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
    
    [[self tabBarController] setSelectedIndex:0];
    
    [[[[self tabBarController] tabBar] items][1] setEnabled:NO];
    [[[[self tabBarController] tabBar] items][2] setEnabled:NO];
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
    
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
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
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        return 5;
    }
    else {
        return 4;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [cell prepareForTableView:tableView indexPath:indexPath];
    
    if ([indexPath row] == 0) {
        [[cell textLabel] setText:@"Logout"];
    }
    else if ([indexPath row] == 1) {
        [[cell textLabel] setText:@"Clear Image Cache"];
    }
    else if ([indexPath row] == 2) {
        [[cell textLabel] setText:@"Edit Profile..."];
    }
    else if ([indexPath row] == 3) {
        [[cell textLabel] setText:@"Post to Twitter?"];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setTwitterSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
            [[self twitterSwitch] setOn:YES];
        }
        else {
            [[self twitterSwitch] setOn:NO];
        }
        
        [cell setAccessoryView:[self twitterSwitch]];
        
        [[self twitterSwitch] addTarget:self action:@selector(twitterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        if ([indexPath row] == 4) {
            [[cell textLabel] setText:@"Post to Facebook?"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            [self setFacebookSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
                [[self facebookSwitch] setOn:YES];
            }
            else {
                [[self facebookSwitch] setOn:NO];
            }
            
            [cell setAccessoryView:[self facebookSwitch]];
            
            [[self facebookSwitch] addTarget:self action:@selector(facebookSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
    }
    return cell;
}

-(void)facebookSwitchChanged:(id)sender
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        
        ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        
        NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
        
        if ([accountsArray count] > 0) {
            [[NSUserDefaults standardUserDefaults] setBool:[[self facebookSwitch] isOn] forKey:@"post_to_facebook"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else {
            [[self facebookSwitch] setOn:NO animated:YES];
            
            UIAlertView *noAccounts = [[UIAlertView alloc] initWithTitle:@"No Account"
                                                                 message:@"You don't seem to have a Facebook account set up.  Please set one up in the Settings app."
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil, nil];
            
            [noAccounts show];
        }
    }
}

-(void)twitterSwitchChanged:(id)sender
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
	
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	
    NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
    
    if ([accountsArray count] > 0) {
        [[NSUserDefaults standardUserDefaults] setBool:[[self twitterSwitch] isOn] forKey:@"post_to_twitter"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        [[self twitterSwitch] setOn:NO animated:YES];
        
        UIAlertView *noAccounts = [[UIAlertView alloc] initWithTitle:@"No Account"
                                                             message:@"You don't seem to have a Twitter account set up.  Please set one up in the Settings app."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil];
        
        [noAccounts show];
    }
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
        case 2:
            [self performSegueWithIdentifier:@"EditUser" sender:self];
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
            
            NSString *directory = paths[0];
            
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
        [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
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
