//
//  AppDelegate.m
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#ifdef _USE_OS_6_OR_LATER
#import <Social/Social.h>
#endif
#import "TestFlight.h"
#import "TMImgurUploader.h"
#import "YISplashScreen.h"
#import "YISplashScreenAnimation.h"
#import "FeedViewController.h"

@implementation UIApplication (Private)

- (BOOL)customOpenURL:(NSURL*)url
{
    SEL selector = @selector(handleURL:);
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if ([appDelegate currentViewController]) {
        [[appDelegate currentViewController] performSelectorOnMainThread:selector withObject:url waitUntilDone:NO];
        return YES;
    }
    return NO;
}

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize userID;

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [YISplashScreen show];
    
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString *UUID = [NSString stringWithFormat:@"%@", UUIDSRef];
    
    CFRelease(UUIDSRef);
    CFRelease(UUIDRef);
    
    [TestFlight takeOff:kTestFlightAPIKey];
    
    [[TMImgurUploader sharedInstance] setAPIKey:kImgurAPIKey];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        [TestFlight setDeviceIdentifier:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
    }
    else {
        [TestFlight setDeviceIdentifier:UUID];
    }
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@NO: @"post_to_twitter",
     @NO: @"post_to_facebook",
     @NO: @"confirm_post"}];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound)];
    
    Method customOpenUrl = class_getInstanceMethod([UIApplication class], @selector(customOpenURL:));
    Method openUrl = class_getInstanceMethod([UIApplication class], @selector(openURL:));
    
    method_exchangeImplementations(openUrl, customOpenUrl);
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"read_username_from_defaults"]) {
        [YISplashScreen hide];
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    else {
        UIWindow *tempWindow = [kAppDelegate window];
        
        if ([[UIApplication sharedApplication] statusBarFrame].size.height > 20) {
            [[kAppDelegate window] setFrame:CGRectMake(tempWindow.frame.origin.x, tempWindow.frame.origin.y + 40, tempWindow.frame.size.width, tempWindow.frame.size.height - 40)];
        }
        else {
            if (tempWindow.frame.size.height > 500) {
                [[kAppDelegate window] setFrame:CGRectMake(0, 0, tempWindow.frame.size.width, 548)];
            }
            else {
                [[kAppDelegate window] setFrame:CGRectMake(0, 0, tempWindow.frame.size.width, 460)];
            }
        }
    }
    
    [self setExternalImageCache:[[NSCache alloc] init]];
    
    return YES;
}

-(void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	NSString *deviceTokenString = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[NSUserDefaults standardUserDefaults] setValue:deviceTokenString forKey:@"deviceToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
#if (TARGET_IPHONE_SIMULATOR)
    return;
#else
    NSString *apnsErrorString = [NSString stringWithFormat:@"Error: %@", [err localizedDescription]];
    
    NSLog(apnsErrorString, nil);
#endif
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSString *alertString = [NSString stringWithFormat:@"%@", userInfo[@"aps"][@"alert"]];
    
    if ([application applicationState] == UIApplicationStateActive) {
        BlockAlertView *pushAlert = [[BlockAlertView alloc] initWithTitle:@"Jukaela Social" message:alertString];
        
        [pushAlert setCancelButtonWithTitle:@"OK" block:nil];
        
        [pushAlert show];
    }
}

-(void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

-(void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
