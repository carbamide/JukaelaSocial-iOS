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
#import "SFHFKeychainUtils.h"
#import "TestFlight.h"

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
    BlockActionSheet *logOutActionSheet = [[BlockActionSheet alloc] initWithTitle:nil];
    
    [logOutActionSheet setDestructiveButtonWithTitle:@"Logout" block:^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kReadUsernameFromDefaultsPreference];
        
        [SFHFKeychainUtils deleteItemForUsername:[[NSUserDefaults standardUserDefaults] valueForKey:kUsername] andServiceName:kJukaelaSocialServiceName error:nil];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUsername];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserID];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[[self tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
        
        [[self tabBarController] setSelectedIndex:0];
        
        [[[[self tabBarController] tabBar] items][1] setEnabled:NO];
        [[[[self tabBarController] tabBar] items][2] setEnabled:NO];
        [[[[self tabBarController] tabBar] items][3] setEnabled:NO];
        [[[[self tabBarController] tabBar] items][4] setEnabled:NO];
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
    [[self view] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    [self setPickerView:[[UIPickerView alloc] init]];
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
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [[cell textLabel] setFont:[UIFont fontWithName:kHelveticaLight size:18]];
    
    [cell prepareForTableView:tableView indexPath:indexPath];
    
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
            [[cell textLabel] setText:@"Default Icon Style"];
            
            if ([[NSUserDefaults standardUserDefaults] stringForKey:@"avatar_type"]) {
                [[cell detailTextLabel] setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"avatar_type"]];
            }
            
            [[cell detailTextLabel] setFont:[UIFont fontWithName:@"Helvetica-Light" size:10]];
            
            [[cell detailTextLabel] setTextColor:[UIColor darkGrayColor]];
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
                            
                            BlockAlertView *noAccount = [[BlockAlertView alloc] initWithTitle:@"No Accounts" message:@"You don't seem to have a Facebook account set up.  Please set one up in the Settings app."];
                            
                            [noAccount setCancelButtonWithTitle:@"OK" block:nil];
                            
                            [noAccount show];
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
                            
                            BlockAlertView *noAccount = [[BlockAlertView alloc] initWithTitle:@"No Accounts" message:@"You don't seem to have a Twitter account set up.  Please set one up in the Settings app."];
                            
                            [noAccount setCancelButtonWithTitle:@"OK" block:nil];
                            
                            [noAccount show];
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
            if ([indexPath row] == 2) {
                if ([[self pickerView] superview] == nil)
                {
                    [[[self view] window] addSubview:[self pickerView]];
                    
                    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
                    CGSize pickerSize = [[self pickerView] sizeThatFits:CGSizeZero];
                    CGRect startRect = CGRectMake(0.0, screenRect.origin.y + screenRect.size.height, pickerSize.width, pickerSize.height);
                    
                    [[self pickerView] setFrame:startRect];
                    
                    CGRect pickerRect;
                    
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        pickerRect = CGRectMake(0, screenRect.origin.y + screenRect.size.height - pickerSize.height, screenRect.size.width, pickerSize.height);
                    }
                    else {
                        pickerRect = CGRectMake(0.0, screenRect.origin.y + screenRect.size.height - pickerSize.height, pickerSize.width, pickerSize.height);
                    }
                    
                    [UIView beginAnimations:nil context:NULL];
                    [UIView setAnimationDuration:0.3];
                    [UIView setAnimationDelegate:self];
                    
                    [[self pickerView] setFrame:pickerRect];
                    
                    CGRect newFrame = [[self tableView] frame];
                    
                    newFrame.size.height -= [self pickerView].frame.size.height;
                    
                    [[self tableView] setFrame:newFrame];
                    [UIView commitAnimations];
                    
                    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)]];
                }
            }
            return;
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
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    CGRect endFrame = [self pickerView].frame;
    endFrame.origin.y = screenRect.origin.y + screenRect.size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(slideDownDidStop)];
    
    [[self pickerView] setFrame:endFrame];
    
    [UIView commitAnimations];
    
    CGRect newFrame = [[self tableView] frame];
    newFrame.size.height += [self pickerView].frame.size.height;
    
    [[self tableView] setFrame:newFrame];
    
    [[self navigationItem] setRightBarButtonItem:nil];
    
    NSIndexPath *indexPath = [[self tableView] indexPathForSelectedRow];
    
    [self clearImageCache];
    
    [[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)clearImageCache
{
    BlockActionSheet *eraseAction = [[BlockActionSheet alloc] initWithTitle:nil];
    
    [eraseAction setDestructiveButtonWithTitle:@"Clear Image Cache" block:^{
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
        
        [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
    }];
    
    [eraseAction setCancelButtonWithTitle:@"Cancel" block:nil];
    
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
    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    
    [[cell detailTextLabel] setText:[self pickerViewComponents][row]];
    
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

@end
