//
//  JukaelaCollectionViewController.h
//  Jukaela
//
//  Created by Josh on 12/10/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@import UIKit;

#import "UsersCollectionViewCell.h"
#import "MBProgressHUD.h"
#import "ActivityManager.h"
#import "RIButtonItem.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "RequestFactory.h"

@interface JukaelaCollectionViewController : UICollectionViewController <MBProgressHUDDelegate>

@property (nonatomic) BOOL showBackgroundImage;

@end
