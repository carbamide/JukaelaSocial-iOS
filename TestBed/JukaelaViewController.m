//
//  JukaelaViewController.m
//  Jukaela
//
//  Created by Josh on 8/8/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaViewController.h"

@implementation JukaelaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *) imageWithView:(UIView *)view
{
    
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[[[self view] window] screen] scale]);
    /*
     Note that in seed 1, drawViewHierarchyInRect: does not function correctly. This has been fixed in seed 2. Seed 1 users will have empty images returned to them.
     */
    [view drawViewHierarchyInRect:CGRectMake(view.frame.origin.x, view.frame.origin.y, CGRectGetWidth(view.frame), CGRectGetHeight(view.frame))];
    
    UIImage *newBGImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    newBGImage = [newBGImage applyLightEffect];
    
    return newBGImage;
}

@end
