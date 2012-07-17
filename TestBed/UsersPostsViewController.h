//
//  UsersPostsViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/17/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UsersPostsViewController : UITableViewController

@property (strong, nonatomic) NSArray *userPostArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSString *userID;

@end
