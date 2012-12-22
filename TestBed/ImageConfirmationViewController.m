//
//  ImageConfirmationViewController.m
//  Jukaela
//
//  Created by Josh on 12/7/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "ImageConfirmationViewController.h"
#import "PostViewController.h"

@interface ImageConfirmationViewController ()

@end

@implementation ImageConfirmationViewController

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
	
    [self setTitle:@"Preview"];
    
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStyleBordered target:self action:@selector(confirmImage:)]];
    
    [[self imageView] setImage:[self theImage]];
}

-(void)viewDidAppear:(BOOL)animated
{
    [kAppDelegate setCurrentViewController:self];

    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setImageView:nil];
    [super viewDidUnload];
}

-(void)confirmImage:(id)sender
{
    [_delegate finishImagePicking:[self theImage] withImagePickerController:[self pickerController]];
}


@end
