//
//  PostViewController.m
//  Jukaela
//
//  Created by Josh Barrow on 5/16/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#import "PostViewController.h"
#import "NSString+BackslashEscape.h"

@interface PostViewController ()

@end

@implementation PostViewController

@synthesize replyString;
@synthesize repostString;
@synthesize theTextView;

- (void)viewDidLoad
{    
    [super viewDidLoad];
    
    [self customizeNavigationBar];
    
    [self setupNavbarForPosting];
}

-(void)viewDidAppear:(BOOL)animated
{
    if (replyString) {
        theTextView = [[YIPopupTextView alloc] initWithText:[self replyString] maxCount:140];
    }
    else if (repostString) {
        theTextView = [[YIPopupTextView alloc] initWithText:[self repostString] maxCount:140];
    }
    else {
        theTextView = [[YIPopupTextView alloc] initWithPlaceHolder:@"Make a post, you guys!" maxCount:140];
    }
    
    [theTextView setDelegate:self];
    [theTextView setShowCloseButton:NO];
    
    [theTextView showInView:[self view]];
}
-(void)customizeNavigationBar
{
    PrettyNavigationBar *navBar = (PrettyNavigationBar *)self.navigationController.navigationBar;
    
    [navBar setTopLineColor:[UIColor colorWithHex:0xafafaf]];
    [navBar setGradientStartColor:[UIColor colorWithHex:0x969696]];
    [navBar setGradientEndColor:[UIColor colorWithHex:0x3e3e3e]];
    [navBar setBottomLineColor:[UIColor colorWithHex:0x303030]];
    [navBar setTintColor:[navBar gradientEndColor]];
}

-(void)setupNavbarForPosting
{
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendPost:)];
    
    [[self navigationItem] setRightBarButtonItem:sendButton];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPost:)];
    
    [[self navigationItem] setLeftBarButtonItem:cancelButton];
}

-(void)cancelPost:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)sendPost:(id)sender
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    
    [activityView sizeToFit];
    
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | 
                                       UIViewAutoresizingFlexibleRightMargin | 
                                       UIViewAutoresizingFlexibleTopMargin | 
                                       UIViewAutoresizingFlexibleBottomMargin)];
    [activityView startAnimating];
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
    [[self navigationItem] setRightBarButtonItem:loadingView];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts.json", kSocialURL]];
    
    NSString *stringToSendAsContent = [[[self theTextView] text] stringWithSlashEscapes];
    
    NSLog(@"%@", [[self theTextView] text]);
    
    NSString *requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", stringToSendAsContent, [kAppDelegate userID]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {                
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

-(void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text
{
    NSLog(@"Herpy derpty");
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
