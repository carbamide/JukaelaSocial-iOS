//
//  JukaelaTableViewController.h
//  Jukaela
//
//  Created by Josh on 8/8/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@import MessageUI;
@import ObjectiveC.runtime;

#import "ApiFactory.h"
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "NormalCellView.h"
#import "NormalWithImageCellView.h"
#import "SORelativeDateTransformer.h"
#import "SVModalWebViewController.h"
#import "JukaelaTableViewProtocol.h"
#import "MBProgressHUD.h"
#import "User.h"
#import "FeedItem.h"
#import "MentionItem.h"
#import "ActivityManager.h"
#import "RIButtonItem.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "RequestFactory.h"

@interface JukaelaTableViewController : UITableViewController <MBProgressHUDDelegate>

@property (strong, nonatomic) NSMutableArray *tableDataSource;
@property (nonatomic) BOOL showBackgroundImage;

- (UIImage *) imageWithView:(UIView *)view;

- (void)handleURL:(NSURL*)url;

-(void)refreshTable;

@end
