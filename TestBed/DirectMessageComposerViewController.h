//
//  DirectMessageComposerViewController.h
//  Jukaela
//
//  Created by Josh on 12/9/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaViewController.h"

@interface DirectMessageComposerViewController : JukaelaViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *countDownLabel;
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;

@property (strong, nonatomic) UITableView *usernameTableView;

-(IBAction)post:(id)sender;
-(IBAction)cancel:(id)sender;

@end
