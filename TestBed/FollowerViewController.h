//
//  FollowerViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface FollowerViewController : JukaelaCollectionViewController <MBProgressHUDDelegate>

@property (strong, nonatomic) NSArray *usersArray;

@end
