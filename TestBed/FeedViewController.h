//
//  FeedViewController.h
//  Jukaela Social
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import "JukaelaTableViewController.h"

NS_ENUM(NSInteger, ChangeType) {
    INSERT_POST,
    DELETE_POST,
    OTHER_CHANGE_TYPE
};

@interface FeedViewController : JukaelaTableViewController <UIScrollViewDelegate, JukaelaTableViewProtocol>

@property (strong, nonatomic) NSDictionary *tempDict;
@property (strong, nonatomic) NSMutableDictionary *nameDict;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UITextView *textView;

@property (nonatomic) BOOL loadedDirectly;

-(void)initializeActivityIndicator;
-(void)refreshControlHandler:(id)sender;

@end
