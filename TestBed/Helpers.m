//
//  Helpers.m
//  Claims Express
//
//  Created by Josh on 8/26/11.
//  Copyright (c) 2011 - 2012 ConnectPoint Resolution Systems, Inc. All rights reserved.
//

#import "Helpers.h"
#import "RIButtonItem.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"

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
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            
            NSString *documentsDirectory = paths[0];
            NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithString:[NSString stringWithFormat:@"%@.png", emailAddress]]];
            
            NSData *data = UIImagePNGRepresentation(image);
            
            [data writeToFile:path atomically:YES];
        });
    }
}

+(NSMutableURLRequest *)getRequestWithURL:(NSURL *)url
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    [request setTimeoutInterval:30];
    
    return request;
}

+(NSMutableURLRequest *)postRequestWithURL:(NSURL *)url withData:(NSData *)data
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    [request setTimeoutInterval:30];
    
    return request;
}

+(void)errorAndLogout:(UIViewController *)aViewController withMessage:(NSString *)aMessage;
{
    RIButtonItem *logoutButton = [RIButtonItem itemWithLabel:@"Logout" action:^{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kReadUsernameFromDefaultsPreference];
        
        [[[aViewController tabBarController] viewControllers][0] popToRootViewControllerAnimated:NO];
        
        [[aViewController tabBarController] setSelectedIndex:0];
        
        for (UITabBarItem *item in [[[aViewController tabBarController] tabBar] items]) {
            [item setEnabled:NO];
        }
    }];
    
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:aMessage cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] otherButtonItems:logoutButton, nil];
    
    [errorAlert show];
}

+(NSString *)documentsPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+(NSArray *)arrayOfURLsFromString:(NSString *)httpLine error:(NSError *)error
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *arrayOfAllMatches = [regex matchesInString:httpLine options:0 range:NSMakeRange(0, [httpLine length])];
    
    NSMutableArray *arrayOfURLs = [[NSMutableArray alloc] init];
    
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        NSString* substringForMatch = [httpLine substringWithRange:match.range];
        
        [arrayOfURLs addObject:substringForMatch];
    }
    
    // return non-mutable version of the array
    return [NSArray arrayWithArray:arrayOfURLs];
}

+(NSArray *)splitString:(NSString*)str maxCharacters:(NSInteger)maxLength
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *wordArray = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger numberOfWords = [wordArray count];
    NSInteger index = 0;
    NSInteger lengthOfNextWord = 0;
    
	while (index < numberOfWords) {
		NSMutableString *line = [NSMutableString stringWithCapacity:1];
		while ((([line length] + lengthOfNextWord + 1) <= maxLength) && (index < numberOfWords)) {
	        lengthOfNextWord = [[wordArray objectAtIndex:index] length];
	        [line appendString:[wordArray objectAtIndex:index]];
	        index++;
            if (index < numberOfWords) {
                [line appendString:@" "];
            }
	    }
		[tempArray addObject:line];
	}
    return tempArray;
}
@end
