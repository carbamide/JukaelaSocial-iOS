//
//  AppDelegate.h
//  Jukaela Social
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SORelativeDateTransformer.h"
#import <RESideMenu/RESideMenu.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSNumber *userID;
@property (strong, nonatomic) NSString *userEmail;
@property (strong, nonatomic) NSString *userUsername;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;

@property (nonatomic, assign) id currentViewController;

@property (nonatomic) BOOL onlyToFacebook;
@property (nonatomic) BOOL onlyToTwitter;
@property (nonatomic) BOOL onlyToJukaela;

@property (strong, readonly, nonatomic) RESideMenu *sideMenu;

@property (strong, nonatomic) UINavigationController *rootViewNavigationController;

-(void)configureNavigationMenu;

@end
