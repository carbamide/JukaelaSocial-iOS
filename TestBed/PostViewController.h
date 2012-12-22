//
//  PostViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/16/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRButtons.h"

@interface PostViewController : JukaelaViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (strong, nonatomic) IBOutlet UIButton *photoButton;
@property (strong, nonatomic) IBOutlet UIImageView *userProfileImage;
@property (strong, nonatomic) IBOutlet UILabel *countDownLabel;
@property (strong, nonatomic) IBOutlet UITextView *theTextView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;

@property (strong, nonatomic) NSString *replyString;
@property (strong, nonatomic) NSString *repostString;
@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) UIImage *imageFromExternalSource;


-(IBAction)takePhoto:(id)sender;
-(IBAction)sendPost:(id)sender;
-(IBAction)cancelPost:(id)sender;

-(void)finishImagePicking:(UIImage *)image withImagePickerController:(UIImagePickerController *)picker;

@end
