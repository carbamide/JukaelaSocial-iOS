//
//  AppDelegate.m
//  Jukaela Social
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

@import ObjectiveC.runtime;

#import "TMImgurUploader.h"
#import "FeedViewController.h"

@interface AppDelegate ()

@property (strong, nonatomic) UINavigationController *mentionsViewNavigationController;
@property (strong, nonatomic) UINavigationController *usersViewNavigationController;
@property (strong, nonatomic) UINavigationController *settingsViewNavigationController;

@end

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
    
    [[self window] setTintColor:[UIColor redColor]];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kReadUsernameFromDefaultsPreference]) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    
    if (tempImage) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kPostImage object:nil userInfo:@{kImageNotification : tempImage}];
    }
    
    [self configureViewControllers];
    
    [self configureNavigationMenu];
    
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
        UIAlertView *pushAlert = [[UIAlertView alloc] initWithTitle:kJukaelaSocialServiceName
                                                            message:alertString
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        
        [pushAlert show];
    }
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([[self currentViewController] isKindOfClass:[FeedViewController class]]) {
        [[self currentViewController] refreshControlHandler:nil];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    UIImage *tempImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPostImage object:nil userInfo:@{kImageNotification : tempImage}];
    
    return YES;
}

-(void)configureNavigationMenu
{
    RESideMenuItem *feedItem = [[RESideMenuItem alloc] initWithTitle:@"Feed" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        [menu setRootViewController:[self rootViewNavigationController]];
    }];
    
    RESideMenuItem *mentionsItem = [[RESideMenuItem alloc] initWithTitle:@"Mentions" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        [menu setRootViewController:[self mentionsViewNavigationController]];
    }];
    
    RESideMenuItem *usersItem = [[RESideMenuItem alloc] initWithTitle:@"Users" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        [menu setRootViewController:[self usersViewNavigationController]];
    }];
    
    RESideMenuItem *settingsItem = [[RESideMenuItem alloc] initWithTitle:@"Settings" action:^(RESideMenu *menu, RESideMenuItem *item) {
        [menu hide];
        
        [menu setRootViewController:[self settingsViewNavigationController]];
    }];
    
    _sideMenu = [[RESideMenu alloc] initWithItems:@[feedItem, mentionsItem, usersItem, settingsItem]];
    
    [_sideMenu setHideStatusBarArea:NO];
}

-(instancetype)viewControllerFromStoryboardNamed:(NSString *)storyboardName andInstantationIdentifier:(NSString *)viewControllerName
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    
    id viewController = [storyboard instantiateViewControllerWithIdentifier:viewControllerName];
    
    return viewController;
}

-(void)configureViewControllers
{
    id loginViewController = [self viewControllerFromStoryboardNamed:@"MainStoryboard" andInstantationIdentifier:@"LoginViewController"];
    [loginViewController setTitle:@"Login"];
    
    id mentionsViewController = [self viewControllerFromStoryboardNamed:@"MainStoryboard" andInstantationIdentifier:@"MentionsViewController"];
    [mentionsViewController setTitle:@"Mentions"];
    
    id usersViewController = [self viewControllerFromStoryboardNamed:@"MainStoryboard" andInstantationIdentifier:@"UsersViewController"];
    [usersViewController setTitle:@"Users"];
    
    id settingsViewController = [self viewControllerFromStoryboardNamed:@"MainStoryboard" andInstantationIdentifier:@"SettingsViewController"];
    [settingsViewController setTitle:@"Settings"];
    
    [self setRootViewNavigationController:[[UINavigationController alloc] initWithRootViewController:loginViewController]];
    [self setMentionsViewNavigationController:[[UINavigationController alloc] initWithRootViewController:mentionsViewController]];
    [self setUsersViewNavigationController:[[UINavigationController alloc] initWithRootViewController:usersViewController]];
    [self setSettingsViewNavigationController:[[UINavigationController alloc] initWithRootViewController:settingsViewController]];
}
@end
