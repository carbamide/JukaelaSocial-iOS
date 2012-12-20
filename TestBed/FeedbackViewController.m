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
    
    [[self feedbackTextView] setFont:[UIFont fontWithName:kFontPreference size:14]];
    
    [[self feedbackTextView] becomeFirstResponder];
    
    [[self view] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(IBAction)submitFeedBack:(id)sender
{
    [TestFlight submitFeedback:[[self feedbackTextView] text]];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
