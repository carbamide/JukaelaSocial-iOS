//
//  ThreadedPostsViewController.h
//  Jukaela
//
//  Created by Josh on 12/26/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@interface ThreadedPostsViewController : JukaelaTableViewController <MBProgressHUDDelegate>

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDictionary *tempDict;
@property (strong, nonatomic) NSMutableArray *threadedPosts;
@property (strong, nonatomic) NSString *userID;

@end
