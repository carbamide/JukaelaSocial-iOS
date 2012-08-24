//
//  ClearLabelsCellView.h
//  ShadowedTableView
//
//  Created by Matt Gallagher on 2009/08/21.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kJKPrepareForReuseNotification;

@interface ClearLabelsCellView : UITableViewCell

@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@property (strong, retain) UILabel *usernameLabel;
@property (strong, retain) UITextView *contentText;

@end
