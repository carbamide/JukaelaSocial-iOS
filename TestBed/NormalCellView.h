//
//  NormalCellView.h
//  Jukaela Social
//
//  Created by Josh Barrow on 09/09/2012.
//  Copyright 2012 Josh Barrow. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kJKPrepareForReuseNotification;

@interface NormalCellView : UITableViewCell <UIGestureRecognizerDelegate>

@property (strong, nonatomic, setter = setDate:) NSString *postDate;
@property (strong, nonatomic) NSTimer *dateTimer;
@property (nonatomic, retain) UILabel *dateLabel;
@property (nonatomic, retain) UILabel *nameLabel;
@property (strong, retain) UILabel *repostedNameLabel;
@property (strong, retain) UILabel *usernameLabel;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@property (strong, nonatomic) UITapGestureRecognizer *imageTapGesture;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@property (strong, retain) UITextView *contentText;

@property (nonatomic, getter = isDisabled) BOOL disabled;

-(void)disableCell;
-(void)doubleTapAction:(UIGestureRecognizer *)gesture;

@end
