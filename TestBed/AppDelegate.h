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
@property (strong, nonatomic) NSCache *imageCache;
@property (strong, nonatomic) NSCache *nameCache;
@property (strong, nonatomic) NSString *userID;

@end
