//
//  FeedViewController.h
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <UIKit/UIKit.h>
#import "JSCoreTextView.h"
#import "MBProgressHUD.h"
#import "MWPhotoBrowser.h"

NS_ENUM(NSInteger, ChangeType) {
    INSERT_POST,
    DELETE_POST,
    OTHER_CHANGE_TYPE
};

@interface FeedViewController : UITableViewController <MBProgressHUDDelegate, MFMailComposeViewControllerDelegate, JSCoreTextViewDelegate, MWPhotoBrowserDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) NSMutableArray *theFeed;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) NSMutableDictionary *nameDict;
@property (strong, nonatomic) NSDictionary *tempDict;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL loadedDirectly;

- (void)initializeActivityIndicator;

@end
