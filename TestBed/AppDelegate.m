//
//  AppDelegate.m
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <Accounts/Accounts.h>
#import <objc/runtime.h>
#import <Social/Social.h>
#import "FeedViewController.h"
#import "TMImgurUploader.h"

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
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
    
    UIImage *tempImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        
    [[TMImgurUploader sharedInstance] setAPIKey:kImgurAPIKey];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@NO: kPostToTwitterPreference,
     @NO: kPostToFacebookPreference,
     @"avatar_type": @"retro"}];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeSound)];
    
    Method customOpenUrl = class_getInstanceMethod([UIApplication class], @selector(customOpenURL:));
    Method openUrl = class_getInstanceMethod([UIApplication class], @selector(openURL:));
    
    method_exchangeImplementations(openUrl, customOpenUrl);
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference]) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
        
    if (tempImage) {        
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kPostImage object:nil userInfo:@{kImageNotification : tempImage}];
    }
        
    return YES;
}

-(void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if (![[NSUserDefaults standardUserDefaults] valueForKey:kDeviceTokenPreference]) {
        NSString *deviceTokenString = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        [[NSUserDefaults standardUserDefaults] setValue:deviceTokenString forKey:kDeviceTokenPreference];
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
        UIAlertView *pushAlert = [[UIAlertView alloc] initWithTitle:kJukaelaSocialServiceName message:alertString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
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
    if ([[self currentViewController] isKindOfClass:[FeedViewController class]]) {
        [[self currentViewController] refreshControlRefresh:nil];
    }
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{    
    UIImage *tempImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPostImage object:nil userInfo:@{kImageNotification : tempImage}];
    
    return YES;
}

@end
