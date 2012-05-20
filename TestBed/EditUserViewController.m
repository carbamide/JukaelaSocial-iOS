//
//  EditUserViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/20/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "EditUserViewController.h"

@interface EditUserViewController ()
-(NSArray *)fieldsArray;
@end

@implementation EditUserViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProfile:)]];
    
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];  

    [super viewDidLoad];
}

-(void)saveProfile:(id)sender
{
    NSLog(@"Nothing here!");
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
        cell = [[PrettyTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        [cell setTableViewBackgroundColor:[tableView backgroundColor]];
    }
    
    [[cell textLabel] setText:[[self fieldsArray] objectAtIndex:[indexPath row]]];
    
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
