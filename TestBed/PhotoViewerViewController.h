//
//  PhotoViewerViewController.h
//  Jukaela
//
//  Created by Josh on 6/16/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoViewerViewController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *mainImageView;

@property (strong, nonatomic) UIImage *mainImage;
@property (strong, nonatomic) UIImage *backgroundImage;

@end
