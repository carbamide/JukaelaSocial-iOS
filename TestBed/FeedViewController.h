//
//  FeedViewController.h
//  Jukaela Social
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "JukaelaTableViewProtocol.h"

NS_ENUM(NSInteger, ChangeType) {
    INSERT_POST,
    DELETE_POST,
    OTHER_CHANGE_TYPE
};

@interface FeedViewController : JukaelaTableViewController <MBProgressHUDDelegate, UIScrollViewDelegate, JukaelaTableViewProtocol>

@property (strong, nonatomic) NSDictionary *tempDict;
@property (strong, nonatomic) NSMutableArray *theFeed;
@property (strong, nonatomic) NSMutableDictionary *nameDict;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UITextView *textView;

@property (nonatomic) BOOL loadedDirectly;

-(void)initializeActivityIndicator;
-(void)refreshControlHandler:(id)sender;

@end
