//
//  FeedbackViewController.h
//  Jukaela
//
//  Created by Josh on 9/15/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JukaelaViewController.h"

@interface FeedbackViewController : JukaelaViewController

@property (strong, nonatomic) IBOutlet UITextView *feedbackTextView;

-(IBAction)submitFeedBack:(id)sender;
-(IBAction)cancel:(id)sender;

@end
