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
#import "YIPopupTextView.h"

@interface FeedViewController : UITableViewController <YIPopupTextViewDelegate, MBProgressHUDDelegate, MFMailComposeViewControllerDelegate, JSCoreTextViewDelegate>

typedef enum {
    INSERT_POST = 0,
    DELETE_POST,
    OTHER_CHANGE_TYPE
} ChangeType;

@property (strong, nonatomic) NSArray *theFeed;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) YIPopupTextView *popupTextView;
@property (strong, nonatomic) NSMutableDictionary *nameDict;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDictionary *tempDict;

@end
