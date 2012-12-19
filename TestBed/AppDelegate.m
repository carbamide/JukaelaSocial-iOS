//
//  AppDelegate.m
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import <Accounts/Accounts.h>

//#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_1
#import <Social/Social.h>
#import <Accounts/Accounts.h>
//#endif
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
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIFont fontWithName:@"Helvetica-Light" size:0.0], UITextAttributeFont,
                                                          nil] forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIFont fontWithName:@"Helvetica-Light" size:0.0], UITextAttributeFont,
                                                          nil] forState:UIControlStateDisabled];
    
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       [UIFont fontWithName:@"Helvetica-Light" size:0.0], UITextAttributeFont,
                                                       nil] forState:UIControlStateNormal];
    
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       [UIFont fontWithName:@"Helvetica-Light" size:0.0], UITextAttributeFont,
                                                       nil] forState:UIControlStateSelected];
    
    
    NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
    
    UIImage *tempImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    
    [TestFlight takeOff:kTestFlightAPIKey];
    
    [[TMImgurUploader sharedInstance] setAPIKey:kImgurAPIKey];
    
    [TestFlight setDeviceIdentifier:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
    
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
    
    [self setExternalImageCache:[[NSCache alloc] init]];
    
    if (tempImage) {
        [YISplashScreen hide];
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"post_image" object:nil userInfo:@{@"image" : tempImage}];
    }
    
    return YES;
}

-(void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"]) {
        NSString *deviceTokenString = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        [[NSUserDefaults standardUserDefaults] setValue:deviceTokenString forKey:@"deviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"%@", [url absoluteString]);
    
    UIImage *tempImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"post_image" object:nil userInfo:@{@"image" : tempImage}];
    
    return YES;
}

@end
