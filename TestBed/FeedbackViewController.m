//
//  FeedbackViewController.m
//  Jukaela
//
//  Created by Josh on 9/15/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "FeedbackViewController.h"

@interface FeedbackViewController ()

@end

@implementation FeedbackViewController

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
    [[[self feedbackTextView] layer] setCornerRadius:8];
    
    [[self feedbackTextView] setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
    
    [[self feedbackTextView] becomeFirstResponder];
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(IBAction)submitFeedBack:(id)sender
{    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
