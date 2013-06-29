//
//  JukaelaCollectionViewController.m
//  Jukaela
//
//  Created by Josh on 12/10/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaCollectionViewController.h"
#import "FeedbackViewController.h"
#import "MentionsViewController.h"
#import "UsersViewController.h"
#import "SettingsViewController.h"

@implementation JukaelaCollectionViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{    
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStyleBordered target:self action:@selector(showMenu)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)showMenu
{
    RESideMenuItem *feedItem = [[RESideMenuItem alloc] initWithTitle:@"Feed" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        id feedViewController = [self viewControllerFromStoryboardNamed:@"MainStoryboard" andInstantationIdentifier:@"FeedViewController"];
        [feedViewController setTitle:[item title]];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:feedViewController];
        [menu setRootViewController:navigationController];
    }];
    
    RESideMenuItem *mentionsItem = [[RESideMenuItem alloc] initWithTitle:@"Mentions" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        id mentionsViewController = [self viewControllerFromStoryboardNamed:@"MainStoryboard" andInstantationIdentifier:@"MentionsViewController"];
        [mentionsViewController setTitle:[item title]];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:mentionsViewController];
        [menu setRootViewController:navigationController];
    }];
    
    RESideMenuItem *usersItem = [[RESideMenuItem alloc] initWithTitle:@"Users" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        id usersViewController = [self viewControllerFromStoryboardNamed:@"MainStoryboard" andInstantationIdentifier:@"UsersViewController"];
        [usersViewController setTitle:[item title]];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:usersViewController];
        [menu setRootViewController:navigationController];
    }];
    
    RESideMenuItem *settingsItem = [[RESideMenuItem alloc] initWithTitle:@"Settings" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        id settingsViewController = [self viewControllerFromStoryboardNamed:@"MainStoryboard" andInstantationIdentifier:@"SettingsViewController"];
        [settingsViewController setTitle:[item title]];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
        [menu setRootViewController:navigationController];
    }];
    
    _sideMenu = [[RESideMenu alloc] initWithItems:@[feedItem, mentionsItem, usersItem, settingsItem]];
    
    [_sideMenu setVerticalOffset:76];
    [_sideMenu setHideStatusBarArea:NO];
    
    [_sideMenu show];
}

-(instancetype)viewControllerFromStoryboardNamed:(NSString *)storyboardName andInstantationIdentifier:(NSString *)viewControllerName
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    
    id viewController = [storyboard instantiateViewControllerWithIdentifier:viewControllerName];
    
    return viewController;
}

@end
