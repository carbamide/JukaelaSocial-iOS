//
//  EditUserViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/20/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "EditUserViewController.h"
#import "AppDelegate.h"

@interface EditUserViewController ()
-(NSArray *)fieldsArray;
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

- (void)viewDidLoad
{
    [self customizeNavigationBar];
    
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];
    
    [[self tableView] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];

    [super viewDidLoad];
}

-(IBAction)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)saveProfile:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@", [kAppDelegate userID], kSocialURL]];
//    
//    "user"=>{"name"=>"Josh Barrow", "username"=>"josh", "email"=>"josh@jukaela.com", "password"=>"yOkzHT8d", "password_confirmation"=>"yOkzhT8d", "profile"=>"This is the song that never ends, yes it goes on and on my friends!", "show_username"=>"0"}, "commit"=>"Save changes", "action"=>"update", "controller"=>"users", "id"=>"101"}
    
    NSString *requestString = [NSString stringWithFormat:@"{\"user\":\"%@\",\"username\":%@, \"email\":%@, \"password\":%@, \"password_confirmation\":%@, \"profile\":%@}", [[self nameTextField] text], [[self usernameTextField] text], [[self emailTextField] text], [[self passwordTextField] text], [[self passwordConfirmTextField] text], [[self profileTextField] text]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
 
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        NSLog(@"%@", [response description]);
         
        [self dismissViewControllerAnimated:YES completion:nil];
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
    static NSString *CellIdentifier = @"Cell";
    
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
        
        [cell setAccessoryView:[self passwordTextField]];
    }
    if ([indexPath row] == 4) {
        [[cell textLabel] setText:@"Confirm Password"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [self setPasswordConfirmTextField:[[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)]];
        
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
