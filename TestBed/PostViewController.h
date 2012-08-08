//
//  PostViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/16/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YIPopupTextView.h"

@interface PostViewController : JukaelaViewController <YIPopupTextViewDelegate>

@property (strong, nonatomic) NSString *replyString;
@property (strong, nonatomic) NSString *repostString;
@property (strong, nonatomic) YIPopupTextView *theTextView;

@end
