//
//  SettingsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "AppDelegate.h"
#import "SettingsViewController.h"
#ifdef __IPHONE_6_0
#endif
#import "TestFlight.h"

@interface SettingsViewController ()

typedef enum {
    FacebookType,
    TwitterType,
    ConfirmType
} SocialTypes;

@property (strong, nonatomic) UISwitch *facebookSwitch;
@property (strong, nonatomic) UISwitch *twitterSwitch;
@property (strong, nonatomic) UISwitch *confirmSwitch;
@end

@implementation SettingsViewController

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];
    
    [super viewDidAppear:animated];
}

-(void)logOut:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"read_username_from_defaults"];
    
    [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
    
    [[self tabBarController] setSelectedIndex:0];
    
    [[[[self tabBarController] tabBar] items][1] setEnabled:NO];
    [[[[self tabBarController] tabBar] items][2] setEnabled:NO];
    [[[[self tabBarController] tabBar] items][3] setEnabled:NO];
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
        return 7;
    }
    else {
        return 6;
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
        [[cell textLabel] setText:@"Submit Feedback..."];
    }
    else if ([indexPath row] == 4) {
        [[cell textLabel] setText:@"Post to Twitter?"];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setTwitterSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
        [[self twitterSwitch] setTag:TwitterType];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
            [[self twitterSwitch] setOn:YES];
        }
        else {
            [[self twitterSwitch] setOn:NO];
        }
        
        [cell setAccessoryView:[self twitterSwitch]];
        
        [[self twitterSwitch] addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        if ([indexPath row] == 5) {
            [[cell textLabel] setText:@"Post to Facebook?"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            [self setFacebookSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
            [[self facebookSwitch] setTag:FacebookType];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
                [[self facebookSwitch] setOn:YES];
            }
            else {
                [[self facebookSwitch] setOn:NO];
            }
            
            [cell setAccessoryView:[self facebookSwitch]];
            
            [[self facebookSwitch] addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        if ([indexPath row] == 6) {
            [[cell textLabel] setText:@"Confirm Posting?"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            [self setConfirmSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
            [[self confirmSwitch] setTag:ConfirmType];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"confirm_post"]) {
                [[self confirmSwitch] setOn:YES];
            }
            else {
                [[self confirmSwitch] setOn:NO];
            }
            
            [cell setAccessoryView:[self confirmSwitch]];
            
            [[self confirmSwitch] addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
    }
    else if ([indexPath row] == 5) {
        [[cell textLabel] setText:@"Confirm Posting?"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setConfirmSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
        [[self confirmSwitch] setTag:ConfirmType];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"confirm_post"]) {
            [[self confirmSwitch] setOn:YES];
        }
        else {
            [[self confirmSwitch] setOn:NO];
        }
        
        [cell setAccessoryView:[self confirmSwitch]];
        
        [[self confirmSwitch] addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    return cell;
}

-(void)switchChanged:(id)sender
{
    switch ([sender tag]) {
        case 0:
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
                    
                    BlockAlertView *noAccount = [[BlockAlertView alloc] initWithTitle:@"No Accounts" message:@"You don't seem to have a Facebook account set up.  Please set one up in the Settings app."];
                    
                    [noAccount setCancelButtonWithTitle:@"OK" block:nil];
                    
                    [noAccount show];
                }
            }
        }
            break;
        case 1:
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
                
                BlockAlertView *noAccount = [[BlockAlertView alloc] initWithTitle:@"No Accounts" message:@"You don't seem to have a Twitter account set up.  Please set one up in the Settings app."];
                
                [noAccount setCancelButtonWithTitle:@"OK" block:nil];
                
                [noAccount show];
            }
        }
            break;
        case 2:
        {
            [[NSUserDefaults standardUserDefaults] setBool:[[self confirmSwitch] isOn] forKey:@"confirm_post"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
            break;
        default:
            break;
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
        case 3:
            [TestFlight openFeedbackView];
            
            [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
            
            break;
        default:
            break;
    }
}

-(void)clearImageCache
{
    BlockActionSheet *eraseAction = [[BlockActionSheet alloc] initWithTitle:nil];
    
    [eraseAction addButtonWithTitle:@"Clear Cache" block:^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            NSError *error = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSString *directory = paths[0];
            
            for (NSString *file in [fileManager contentsOfDirectoryAtPath:directory error:&error]) {
                NSString *filePath = [directory stringByAppendingPathComponent:file];
                
                BOOL fileDeleted = [fileManager removeItemAtPath:filePath error:&error];
                
                if (fileDeleted != YES || error != nil) {
                    BlockAlertView *errorAlert = [[BlockAlertView alloc] initWithTitle:@"Error" message:@"There has been an error.  Please reinstall Jukaela Social."];
                    
                    [errorAlert setCancelButtonWithTitle:@"OK" block:nil];
                    
                    [errorAlert show];
                }
            }
        }
        [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
    }];
    
    [eraseAction setCancelButtonWithTitle:@"Cancel" block:nil];
    
    [eraseAction showInView:[self view]];
}

@end
