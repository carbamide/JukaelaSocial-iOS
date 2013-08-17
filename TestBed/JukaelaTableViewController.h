//
//  JukaelaTableViewController.h
//  Jukaela
//
//  Created by Josh on 8/8/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JukaelaTableViewController : UITableViewController

- (UIImage *) imageWithView:(UIView *)view;

- (void)handleURL:(NSURL*)url;

@end
