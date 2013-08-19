//
//  JukaelaCollectionViewController.m
//  Jukaela
//
//  Created by Josh on 12/10/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaCollectionViewController.h"

@interface JukaelaCollectionViewController()

@property (strong, nonatomic) UIImageView *backgroundImageView;

@end

@implementation JukaelaCollectionViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _backgroundImageView = false;
    }
    return self;
}

- (void)viewDidLoad
{    
    [super viewDidLoad];
    
    [self setupBackground];
    
    if (self == [[self navigationController] viewControllers][0]) {
        [[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStyleBordered target:self action:@selector(showMenu)]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)showMenu
{
    [[kAppDelegate sideMenu] show];
}

-(void)setupBackground
{
    UIImage *image = [Helpers loginImage];
    
    [self setBackgroundImageView:[[UIImageView alloc] initWithImage:image]];
    
    [[self backgroundImageView] setFrame:[[self collectionView] frame]];
    [[self backgroundImageView] setContentMode:UIViewContentModeScaleAspectFill];
    
    [[self collectionView] setBackgroundView:[self backgroundImageView]];
}

-(void)setShowBackgroundImage:(BOOL)showBackgroundImage
{
    _showBackgroundImage = showBackgroundImage;
    
    [[self backgroundImageView] setHidden:!showBackgroundImage];
}

#pragma mark MBProgressHUD Delegate

-(void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
}

@end
