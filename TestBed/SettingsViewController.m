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
#import "SFHFKeychainUtils.h"

NS_ENUM(NSInteger, SocialTypes) {
    FacebookType,
    TwitterType,
    ConfirmType
};

@interface SettingsViewController ()

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
    BlockActionSheet *logOutActionSheet = [[BlockActionSheet alloc] initWithTitle:nil];
    
    [logOutActionSheet setDestructiveButtonWithTitle:@"Logout" block:^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"read_username_from_defaults"];
        
        [SFHFKeychainUtils deleteItemForUsername:[[NSUserDefaults standardUserDefaults] valueForKey:@"username"] andServiceName:@"Jukaela Social" error:nil];

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"user_id"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
        
        [[self tabBarController] setSelectedIndex:0];
        
        [[[[self tabBarController] tabBar] items][1] setEnabled:NO];
        [[[[self tabBarController] tabBar] items][2] setEnabled:NO];
        [[[[self tabBarController] tabBar] items][3] setEnabled:NO];
    }];
    
    [logOutActionSheet setCancelButtonWithTitle:@"Cancel" block:nil];
    
    [logOutActionSheet showInView:[self view]];
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
    return 5;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
                return 3;
            }
            else {
                return 2;
            }
            break;
        case 1:
            return 1;
            break;
        case 2:
            return 1;
            break;
        case 3:
            return 1;
            break;
        case 4:
            return 1;
            break;
        default:
            return 1;
            break;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [[cell textLabel] setFont:[UIFont fontWithName:@"Helvetica-Light" size:18]];

    [cell prepareForTableView:tableView indexPath:indexPath];
    
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
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
            if ([indexPath row] == 1) {
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
            if ([indexPath row] == 2) {
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
        else if ([indexPath row] == 1) {
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
    else if ([indexPath section] == 1) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Edit Profile..."];
        }
    }
    else if ([indexPath section] == 2) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Submit Feedback..."];
        }
    }
    else if ([indexPath section] == 3) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Clear Image Cache"];
        }
    }
    else if ([indexPath section] == 4) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Logout"];
        }
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
                                
                NSDictionary *options = @{ACFacebookAppIdKey:@"493749340639998", ACFacebookAudienceKey: ACFacebookAudienceEveryone, ACFacebookPermissionsKey: @[@"publish_stream", @"publish_actions", @"read_friendlists"]};
                
                [accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error) {
                    if(granted) {
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
                }];
            }
        }
            break;
        case 1:
        {
            ACAccountStore *accountStore = [[ACAccountStore alloc] init];
            
            ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
            
            [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
                if (granted) {
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
            }];
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
    switch ([indexPath section]) {
        case 0:
            return;
            break;
        case 1:
            [self performSegueWithIdentifier:@"EditUser" sender:self];
            
            [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
            break;
        case 2:
            [self performSegueWithIdentifier:@"SubmitFeedback" sender:self];
            
            [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
            break;
        case 3:
            [self clearImageCache];
            
            [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
            break;
        case 4:
            [self logOut:nil];
            
            [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
            break;
        default:
            break;
    }
}

-(void)clearImageCache
{
    BlockActionSheet *eraseAction = [[BlockActionSheet alloc] initWithTitle:nil];
    
    [eraseAction setDestructiveButtonWithTitle:@"Clear Cache" block:^{
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
        
        [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
    }];
    
    [eraseAction setCancelButtonWithTitle:@"Cancel" block:nil];
    
    [eraseAction showInView:[self view]];
}

@end
