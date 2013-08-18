//
//  JukaelaTableViewController.h
//  Jukaela
//
//  Created by Josh on 8/8/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <objc/runtime.h>
#import "ApiFactory.h"
#import "CellBackground.h"
#import "GravatarHelper.h"
#import "JEImages.h"
#import "NormalCellView.h"
#import "NormalWithImageCellView.h"
#import "SORelativeDateTransformer.h"
#import "SVModalWebViewController.h"
#import "JukaelaTableViewProtocol.h"
#import "MBProgressHUD.h"
#import "User.h"
#import "FeedItem.h"
#import "MentionItem.h"

@interface JukaelaTableViewController : UITableViewController <MBProgressHUDDelegate>

@property (strong, nonatomic) NSMutableArray *tableDataSource;

- (UIImage *) imageWithView:(UIView *)view;

- (void)handleURL:(NSURL*)url;

@end
