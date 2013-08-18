//
//  SettingsViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "SettingsViewController.h"

NS_ENUM(NSInteger, SocialTypes) {
    FacebookType,
    TwitterType,
    BadgeType
};

@interface SettingsViewController ()
@property (strong, nonatomic) UISwitch *facebookSwitch;
@property (strong, nonatomic) UISwitch *twitterSwitch;
@property (strong, nonatomic) UIPickerView *pickerView;

@end

@implementation SettingsViewController

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
        [[self twitterSwitch] setOn:YES];
    }
    else {
        [[self twitterSwitch] setOn:NO];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
        [[self facebookSwitch] setOn:YES];
    }
    else {
        [[self facebookSwitch] setOn:NO];
    }
    
    [super viewDidAppear:animated];
}

-(void)logOut:(id)sender
{
    RIButtonItem *logoutButton = [RIButtonItem itemWithLabel:@"Logout" action:^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kReadUsernameFromDefaultsPreference];
        
        [SFHFKeychainUtils deleteItemForUsername:[[NSUserDefaults standardUserDefaults] valueForKey:kUsername] andServiceName:kJukaelaSocialServiceName error:nil];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUsername];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserID];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
        
        [[self tabBarController] setSelectedIndex:0];
        
        for (UITabBarItem *item in [[[self tabBarController] tabBar] items]) {
            [item setEnabled:NO];
        }
    }];
    
    UIActionSheet *logoutActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] destructiveButtonItem:logoutButton otherButtonItems:nil, nil];
    
    [logoutActionSheet showInView:[self view]];
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
    [self setPickerView:[[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 216)]];
    [[self pickerView] setDelegate:self];
    [[self pickerView] setShowsSelectionIndicator:YES];
    
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
            return 3;
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [[cell textLabel] setFont:[UIFont fontWithName:kHelveticaLight size:18]];
    
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            [[cell textLabel] setText:@"Post to Twitter?"];
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            [self setTwitterSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
            [[self twitterSwitch] setTag:TwitterType];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToTwitterPreference]) {
                [[self twitterSwitch] setOn:YES];
            }
            else {
                [[self twitterSwitch] setOn:NO];
            }
            
            [cell setAccessoryView:[self twitterSwitch]];
            
            [[self twitterSwitch] addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        else if ([indexPath row] == 1) {
            [[cell textLabel] setText:@"Post to Facebook?"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            [self setFacebookSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
            [[self facebookSwitch] setTag:FacebookType];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostToFacebookPreference]) {
                [[self facebookSwitch] setOn:YES];
            }
            else {
                [[self facebookSwitch] setOn:NO];
            }
            
            [cell setAccessoryView:[self facebookSwitch]];
            
            [[self facebookSwitch] addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        else if ([indexPath row] == 2) {
            [[self pickerView] setFrame:CGRectInset([cell frame], 0, -70)];
            
            [cell addSubview:[self pickerView]];
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
            if ([sender isOn]) {
                ACAccountStore *accountStore = [[ACAccountStore alloc] init];
                
                ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
                
                NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
                
                NSDictionary *options = @{ACFacebookAppIdKey:@"493749340639998", ACFacebookAudienceKey: ACFacebookAudienceEveryone, ACFacebookPermissionsKey: @[@"email"]};
                
                [accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error) {
                    if(granted) {
                        if ([accountsArray count] > 0) {
                            [[NSUserDefaults standardUserDefaults] setBool:[[self facebookSwitch] isOn] forKey:kPostToFacebookPreference];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                        }
                        else {
                            [[self facebookSwitch] setOn:NO animated:YES];
                        }
                    }
                }];
                
            }
            else {
                [[NSUserDefaults standardUserDefaults] setBool:[[self facebookSwitch] isOn] forKey:kPostToFacebookPreference];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
            break;
        case 1:
        {
            if ([sender isOn]) {
                ACAccountStore *accountStore = [[ACAccountStore alloc] init];
                
                ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
                
                [accountStore requestAccessToAccountsWithType:accountType options:0 completion:^(BOOL granted, NSError *error) {
                    if (granted) {
                        NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
                        if ([accountsArray count] > 0) {
                            [[NSUserDefaults standardUserDefaults] setBool:[[self twitterSwitch] isOn] forKey:kPostToTwitterPreference];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                        }
                        else {
                            [[self twitterSwitch] setOn:NO animated:YES];
                        }
                    }
                }];
                
            }
            else {
                [[NSUserDefaults standardUserDefaults] setBool:[[self twitterSwitch] isOn] forKey:kPostToTwitterPreference];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
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
            break;
        case 1:
            [self performSegueWithIdentifier:kShowEditUser sender:self];
            
            [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
            break;
        case 2:
            [self performSegueWithIdentifier:kShowSubmitFeedback sender:self];
            
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

- (void)slideDownDidStop
{
    [[self pickerView] removeFromSuperview];
}

-(void)doneAction:(id)sender
{
    NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
    
    [self clearImageCache];
    
    [[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)clearImageCache
{
    RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:@"Clear Image Cache" action:^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            NSError *error = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSString *directory = paths[0];
            
            for (NSString *file in [fileManager contentsOfDirectoryAtPath:directory error:&error]) {
                NSString *filePath = [directory stringByAppendingPathComponent:file];
                
                [fileManager removeItemAtPath:filePath error:&error];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
        
        [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
    }];
    
    UIActionSheet *eraseAction = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] destructiveButtonItem:buttonItem otherButtonItems:nil, nil];
    
    [eraseAction showInView:[self view]];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[self pickerViewComponents] count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self pickerViewComponents][row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (row) {
        case 0:
            [[NSUserDefaults standardUserDefaults] setValue:@"mm" forKey:@"avatar_type"];
            
            break;
        case 1:
            [[NSUserDefaults standardUserDefaults] setValue:@"identicon" forKey:@"avatar_type"];
            
            break;
        case 2:
            [[NSUserDefaults standardUserDefaults] setValue:@"monsterid" forKey:@"avatar_type"];
            
            break;
        case 3:
            [[NSUserDefaults standardUserDefaults] setValue:@"wavatar" forKey:@"avatar_type"];
            
            break;
        case 4:
            [[NSUserDefaults standardUserDefaults] setValue:@"retro" forKey:@"avatar_type"];
            
            break;
        default:
            break;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self doneAction:nil];
}

-(NSArray *)pickerViewComponents
{
    return @[@"Mystery Man", @"Identicon", @"Monster ID", @"Wavatar", @"Retro"];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {
        if ([indexPath row] == 2) {
            return 100;
        }
        else {
            return 44;
        }
    }
    else {
        return 44;
    }
}
@end
