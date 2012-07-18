//
//  Constants.h
//  TestBed
//
//  Created by Josh Barrow on 5/4/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import "Helpers.h"
#import "ODRefreshControl.h"
#import "PrettyKit.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Alpha.h"

static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 308;

#define kAppDelegate (AppDelegate *)[[UIApplication sharedApplication] delegate]
#define kSocialURL @"http://localhost:3000"
//#define kSocialURL @"http://cold-planet-7717.herokuapp.com"
#define kPerfectGrey [UIColor colorWithRed:0x71/255.0 green:0x78/255.0 blue:0x80/255.0 alpha:1.0]
#define kPerfectGreyShadow [UIColor colorWithRed:0xe6/255.0 green:0xe7/255.0 blue:0xeb/255.0 alpha:1.0]
static char * const kIndexPathAssociationKey = "Jukaela_index_path";

CGFloat animatedDistance;
