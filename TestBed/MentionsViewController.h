//
//  MentionsViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/17/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface MentionsViewController : JukaelaTableViewController <MBProgressHUDDelegate>

@property (strong, nonatomic) NSMutableArray *mentions;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSDictionary *tempDict;

@end
