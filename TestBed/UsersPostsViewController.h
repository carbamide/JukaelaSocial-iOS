//
//  UsersPostsViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/17/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "MWPhotoBrowser.h"

@interface UsersPostsViewController : UITableViewController <MBProgressHUDDelegate, MWPhotoBrowserDelegate>

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDictionary *tempDict;
@property (strong, nonatomic) NSMutableArray *userPostArray;
@property (strong, nonatomic) NSString *userID;

@end
