//
//  JukaelaTableViewController.m
//  Jukaela
//
//  Created by Josh on 8/8/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaTableViewController.h"
#import "FeedbackViewController.h"
#import "MentionsViewController.h"
#import "UsersViewController.h"
#import "SettingsViewController.h"

@implementation JukaelaTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStyleBordered target:self action:@selector(showMenu)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [[view layer] renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

-(void)showMenu
{
    RESideMenuItem *feedItem = [[RESideMenuItem alloc] initWithTitle:@"Feed" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        FeedbackViewController *secondViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"FeedViewController"];
        
        secondViewController.title = item.title;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];
        [menu setRootViewController:navigationController];
    }];
    RESideMenuItem *mentionsItem = [[RESideMenuItem alloc] initWithTitle:@"Mentions" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        MentionsViewController *secondViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"MentionsViewController"];
        secondViewController.title = item.title;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];
        [menu setRootViewController:navigationController];
    }];
    RESideMenuItem *usersItem = [[RESideMenuItem alloc] initWithTitle:@"Users" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        UsersViewController *secondViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"UsersViewController"];
        secondViewController.title = item.title;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];
        [menu setRootViewController:navigationController];
    }];
    RESideMenuItem *settingsItem = [[RESideMenuItem alloc] initWithTitle:@"Settings" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        SettingsViewController *secondViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingsViewController"];
        secondViewController.title = item.title;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];
        [menu setRootViewController:navigationController];
    }];
    
    _sideMenu = [[RESideMenu alloc] initWithItems:@[feedItem, mentionsItem, usersItem, settingsItem]];
    _sideMenu.verticalOffset = 76;
    _sideMenu.hideStatusBarArea = NO;
    
    [_sideMenu show];
}
@end
