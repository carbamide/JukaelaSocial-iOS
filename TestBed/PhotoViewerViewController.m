//
//  PhotoViewerViewController.m
//  Jukaela
//
//  Created by Josh on 6/16/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "PhotoViewerViewController.h"

@implementation PhotoViewerViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
        
    [[self mainImageView] setUserInteractionEnabled:YES];
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSelf:)];
    
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    
    [[self mainImageView] addGestureRecognizer:swipeGesture];
    
    [[self mainImageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    UILongPressGestureRecognizer *lpGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureHandler:)];
    
    [lpGesture setDelegate:self];
    
    [[self mainImageView] addGestureRecognizer:lpGesture];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[self mainImageView] setImage:[self mainImage]];
    [[self backgroundImageView] setImage:[self backgroundImage]];
}

-(void)dismissSelf:(UIGestureRecognizer *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)longPressGestureHandler:(UIGestureRecognizer *)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        NSArray *activityItems = @[[self mainImage]];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

@end
