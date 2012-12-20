//
//  AppDelegate.h
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *userEmail;
@property (strong, nonatomic) NSString *userUsername;

@property (nonatomic, assign) id currentViewController;

@property (nonatomic) BOOL onlyToFacebook;
@property (nonatomic) BOOL onlyToTwitter;
@property (nonatomic) BOOL onlyToJukaela;

@end
