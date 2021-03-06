//
//  JukaelaViewController.h
//  Jukaela
//
//  Created by Josh on 8/8/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@import UIKit;

#import "SFHFKeychainUtils.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "ObjectMapper.h"
#import "CellBackground.h"
#import "MBProgressHUD.h"
#import "ActivityManager.h"
#import "RIButtonItem.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "RequestFactory.h"

@interface JukaelaViewController : UIViewController <MBProgressHUDDelegate>

- (UIImage *) imageWithView:(UIView *)view;

@end
