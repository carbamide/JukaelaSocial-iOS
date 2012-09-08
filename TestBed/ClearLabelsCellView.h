//
//  ClearLabelsCellView.h
//  ShadowedTableView
//
//  Created by Matt Gallagher on 2009/08/21.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JTextView.h"

extern NSString * const kJKPrepareForReuseNotification;

@interface ClearLabelsCellView : UITableViewCell <UIGestureRecognizerDelegate>

@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@property (strong, retain) UILabel *usernameLabel;
@property (strong, retain) UILabel *repostedNameLabel;
@property (strong, retain) JTextView *contentText;
@property (nonatomic, getter = isDisabled) BOOL disabled;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@property (strong, nonatomic) UITapGestureRecognizer *imageTapGesture;

-(void)disableCell;

@end
