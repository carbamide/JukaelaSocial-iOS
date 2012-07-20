//
//  EditUserViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/20/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "EditUserViewController.h"
#import "AppDelegate.h"
#import "PrettyKit.h"

@interface EditUserViewController ()
-(NSArray *)fieldsArray;
@property (strong, nonatomic) NSDictionary *tempDict;
@end

@implementation EditUserViewController

-(void)customizeNavigationBar
{
    PrettyNavigationBar *navBar = (PrettyNavigationBar *)self.navigationController.navigationBar;
    
    [navBar setTopLineColor:[UIColor colorWithHex:0xafafaf]];
    [navBar setGradientStartColor:[UIColor colorWithHex:0x969696]];
    [navBar setGradientEndColor:[UIColor colorWithHex:0x3e3e3e]];
    [navBar setBottomLineColor:[UIColor colorWithHex:0x303030]];
    [navBar setTintColor:[navBar gradientEndColor]];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

-(void)getUserInfo:(NSString *)userID
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, userID]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self setTempDict:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        [[self nameTextField] setText:[[self tempDict] objectForKey:@"name"]];
        [[self usernameTextField] setText:[[self tempDict] objectForKey:@"username"]];
        [[self emailTextField] setText:[[self tempDict] objectForKey:@"email"]];
        [[self profileTextField] setText:[[self tempDict] objectForKey:@"profile"]];
        
        NSLog(@"%@", [self tempDict]);
    }];
}

- (void)viewDidLoad
{
    [self customizeNavigationBar];
    
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [self getUserInfo:[kAppDelegate userID]];
    
    [super viewDidLoad];
}

-(IBAction)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)saveProfile:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@", kSocialURL, [kAppDelegate userID]]];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"user\": { \"name\":\"%@\",\"username\":\"%@\", \"email\":\"%@\", \"password\":\"%@\", \"password_confirmation\":\"%@\", \"profile\":\"%@\"}}", [[self nameTextField] text], [[self usernameTextField] text], [[self emailTextField] text], [[self passwordTextField] text], [[self passwordConfirmTextField] text], [[self profileTextField] text]];
    
    NSLog(@"%@", requestString);
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (data) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                 message:@"There has been an error saving your updated user information."
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil, nil];
         
            [errorAlert show];
        }
     }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self fieldsArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%d", [indexPath row]];
    
    PrettyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    [[cell textLabel] setText:[[self fieldsArray] objectAtIndex:[indexPath row]]];
    
    if ([indexPath row] == 0) {
        [[cell textLabel] setText:@"Name"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setNameTextField:[[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)]];
        
        [cell setAccessoryView:[self nameTextField]];
    }
    if ([indexPath row] == 1) {
        [[cell textLabel] setText:@"Username"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setUsernameTextField:[[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)]];
        
        [cell setAccessoryView:[self usernameTextField]];
    }
    if ([indexPath row] == 2) {
        [[cell textLabel] setText:@"Email"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setEmailTextField:[[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)]];
        
        [[self emailTextField] setKeyboardAppearance:UIKeyboardTypeEmailAddress];
        
        [cell setAccessoryView:[self emailTextField]];
    }
    if ([indexPath row] == 3) {
        [[cell textLabel] setText:@"Password"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setPasswordTextField:[[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)]];
        
        [[self passwordTextField] setSecureTextEntry:YES];
        
        [cell setAccessoryView:[self passwordTextField]];
    }
    if ([indexPath row] == 4) {
        [[cell textLabel] setText:@"Confirm Password"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setPasswordConfirmTextField:[[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)]];
        
        [[self passwordConfirmTextField] setSecureTextEntry:YES];
        
        [cell setAccessoryView:[self passwordConfirmTextField]];
    }
    if ([indexPath row] == 5) {
        [[cell textLabel] setText:@"Profile"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setProfileTextField:[[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)]];
        
        [cell setAccessoryView:[self profileTextField]];
    }
    [cell prepareForTableView:tableView indexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tempCell setSelected:NO animated:YES];
}

-(NSArray *)fieldsArray
{
    NSArray *tempArray = [NSArray arrayWithObjects:@"Name", @"Username", @"Email", @"Password", @"Confirm Password", @"Profile", nil];
    
    return tempArray;
}

@end
