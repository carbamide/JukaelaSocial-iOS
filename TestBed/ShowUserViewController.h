//
//  ShowUserViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/7/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JukaelaTableViewController.h"

@interface ShowUserViewController : JukaelaTableViewController

@property (strong, nonatomic) NSArray *followers;
@property (strong, nonatomic) NSArray *imFollowing;
@property (strong, nonatomic) NSArray *posts;
@property (strong, nonatomic) NSArray *relationships;
@property (strong, nonatomic) NSDictionary *following;
@property (strong, nonatomic) NSDictionary *userDict;

@end
