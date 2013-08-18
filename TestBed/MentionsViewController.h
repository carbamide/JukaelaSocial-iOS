//
//  MentionsViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/17/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaTableViewController.h"

@interface MentionsViewController : JukaelaTableViewController <MBProgressHUDDelegate, JukaelaTableViewProtocol>

@property (strong, nonatomic) NSDictionary *tempDict;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSString *userID;

@end
