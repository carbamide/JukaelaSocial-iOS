//
//  ThreadedPostsViewController.h
//  Jukaela
//
//  Created by Josh on 12/26/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "MWPhotoBrowser.h"

@interface ThreadedPostsViewController : JukaelaTableViewController <MBProgressHUDDelegate, MWPhotoBrowserDelegate>

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDictionary *tempDict;
@property (strong, nonatomic) NSMutableArray *threadedPosts;
@property (strong, nonatomic) NSString *userID;

@end
