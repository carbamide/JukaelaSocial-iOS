//
//  JukaelaTableViewController.m
//  Jukaela
//
//  Created by Josh on 8/8/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaTableViewController.h"
#import "SVModalWebViewController.h"
#import "FeedViewController.h"

@interface JukaelaTableViewController()

@property (strong, nonatomic) UIImageView *backgroundImageView;

@end

@implementation JukaelaTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBackground];
    
    if (self == [[self navigationController] viewControllers][0] || [self isKindOfClass:[FeedViewController class]]) {
        [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStyleBordered target:self action:@selector(showMenu)]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[[[self view] window] screen] scale]);
    
    [view drawViewHierarchyInRect:CGRectMake(view.frame.origin.x, view.frame.origin.y, CGRectGetWidth(view.frame), CGRectGetHeight(view.frame)) afterScreenUpdates:NO];
    
    UIImage *newBGImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    newBGImage = [newBGImage applyLightEffect];
    
    return newBGImage;
}

-(void)showMenu
{
    [[kAppDelegate sideMenu] show];
}

-(void)setupBackground
{
    UIImage *image = [Helpers loginImage];
    
    [self setBackgroundImageView:[[UIImageView alloc] initWithImage:image]];
    
    [[self backgroundImageView] setFrame:[[self tableView] frame]];
    [[self backgroundImageView] setContentMode:UIViewContentModeScaleAspectFill];
    
    [[self tableView] setBackgroundView:[self backgroundImageView]];
}

-(void)setShowBackgroundImage:(BOOL)showBackgroundImage
{
    _showBackgroundImage = showBackgroundImage;
    
    [[self backgroundImageView] setHidden:!showBackgroundImage];
}

- (void)handleURL:(NSURL*)url
{
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[url absoluteString]];
    
    [webViewController setBarsTintColor:[UIColor darkGrayColor]];
    
    [self presentViewController:webViewController animated:YES completion:nil];
}

#pragma mark MBProgressHUD Delegate

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

@end
