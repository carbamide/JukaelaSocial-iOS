//
//  JukaelaTableViewController.m
//  Jukaela
//
//  Created by Josh on 8/8/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaTableViewController.h"

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
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[[[self view] window] screen] scale]);

    [view drawViewHierarchyInRect:CGRectMake(view.frame.origin.x, view.frame.origin.y, CGRectGetWidth(view.frame), CGRectGetHeight(view.frame))];
    
    UIImage *newBGImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    newBGImage = [newBGImage applyLightEffect];
    
    return newBGImage;
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
