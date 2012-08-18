//
//  Helpers.m
//  Claims Express
//
//  Created by Josh on 8/26/11.
//  Copyright (c) 2011 - 2012 ConnectPoint Resolution Systems, Inc. All rights reserved.
//

#import "Helpers.h"

@implementation Helpers

+(void)moveViewUpFromTextField:(UITextField *)aTextField withView:(UIView *)aView
{
    CGRect textFieldRect = [aView convertRect:[aTextField bounds] fromView:aTextField];
    CGRect viewRect = [aView convertRect:aView.bounds fromView:aView];
    CGFloat midline = textFieldRect.origin.y + 0.5 * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    
    if (heightFraction < 0.0) {
        heightFraction = 0.0;
    }
    else if (heightFraction > 1.0) {
        heightFraction = 1.0;
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT * heightFraction) - 40;
    }
    else {
        animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    }
    
    CGRect viewFrame = aView.frame;
    viewFrame.origin.y -= animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [aView setFrame:viewFrame];
    
    [UIView commitAnimations];
}

+(void)moveViewDown:(UIView *)aView
{
    CGRect viewFrame = aView.frame;
    viewFrame.origin.y += animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [aView setFrame:viewFrame];
    
    [UIView commitAnimations];
}

+(void)saveImage:(UIImage *)image withFileName:(NSString *)emailAddress
{
    if (image != nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = paths[0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithString:[NSString stringWithFormat:@"%@.png", emailAddress]]];
        
        NSData *data = UIImagePNGRepresentation(image);
        
        [data writeToFile:path atomically:YES];
    }
}

+(NSMutableURLRequest *)getRequestWithURL:(NSURL *)url
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    return request;
}

+(NSMutableURLRequest *)postRequestWithURL:(NSURL *)url withData:(NSData *)data
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    return request;
}

+(void)errorAndLogout:(UIViewController *)aViewController withMessage:(NSString *)aMessage;
{
    RIButtonItem *logoutButton = [RIButtonItem itemWithLabel:@"Logout"];
    RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:@"Cancel"];
    
    [logoutButton setAction:^{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"read_username_from_defaults"];
        
        [[[aViewController tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
        
        [[aViewController tabBarController] setSelectedIndex:0];
        
        [[[[aViewController tabBarController] tabBar] items][1] setEnabled:NO];
        [[[[aViewController tabBarController] tabBar] items][2] setEnabled:NO];
    }];
    
    [cancelButton setAction:^{
        return;
    }];
    
    UIAlertView *errorReloadingAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                  message:aMessage
                                                         cancelButtonItem:cancelButton
                                                         otherButtonItems:logoutButton, nil];;
    
    [errorReloadingAlert show];
}
@end
