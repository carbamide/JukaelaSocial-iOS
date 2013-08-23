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

+(void)errorAndLogout:(UIViewController *)aViewController withMessage:(NSString *)aMessage;
{
    RIButtonItem *logoutButton = [RIButtonItem itemWithLabel:@"Logout" action:^{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kReadUsernameFromDefaultsPreference];
    }];
    
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:aMessage cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel" action:nil] otherButtonItems:logoutButton, nil];
    
    [errorAlert show];
}

+(UIImage *)loginImage
{
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[NSString documentsPath] stringByAppendingPathComponent:@"Login"]]];
}

@end
