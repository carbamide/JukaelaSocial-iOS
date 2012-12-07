//
//  NormalCellView.h
//  Jukaela Social
//
//  Created by Josh Barrow on 09/09/2012.
//  Copyright 2012 Josh Barrow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSCoreTextView.h"

extern NSString * const kJKPrepareForReuseNotification;

@interface NormalCellView : UITableViewCell <UIGestureRecognizerDelegate>

@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@property (strong, retain) UILabel *usernameLabel;
@property (strong, retain) UILabel *repostedNameLabel;
@property (strong, retain) JSCoreTextView *contentText;
@property (nonatomic, getter = isDisabled) BOOL disabled;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@property (strong, nonatomic) UITapGestureRecognizer *imageTapGesture;
@property (strong, nonatomic) UITapGestureRecognizer *repostTapGesture;

-(void)disableCell;
-(void)doubleTapAction:(UIGestureRecognizer *)gesture;

@end
