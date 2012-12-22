//
//  ImageConfirmationViewController.h
//  Jukaela
//
//  Created by Josh on 12/7/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PostViewController;

@interface ImageConfirmationViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) UIImage *theImage;
@property (strong, nonatomic) UIImagePickerController *pickerController;

@property (weak) PostViewController *delegate;

-(void)confirmImage:(id)sender;

@end
