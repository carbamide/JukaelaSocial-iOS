//
//  Constants.h
//  TestBed
//
//  Created by Josh Barrow on 5/4/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import "BlockAlertView.h"
#import "BlockActionSheet.h"
#import "Helpers.h"
#import "JukaelaViewController.h"
#import "JukaelaTableViewController.h"
#import "PrettyKit.h"
#import "ODRefreshControl.h"
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
//#define kSocialURL @"http://localhost:3000"
#define kSocialURL @"http://cold-planet-7717.herokuapp.com"
#define kPerfectGrey [UIColor colorWithRed:0x71/255.0 green:0x78/255.0 blue:0x80/255.0 alpha:1.0]
#define kPerfectGreyShadow [UIColor colorWithRed:0xe6/255.0 green:0xe7/255.0 blue:0xeb/255.0 alpha:1.0]
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
static char * const kIndexPathAssociationKey = "Jukaela_index_path";
#define jMIN(a,b) (((a)<(b))?(a):(b))
#define jMAX(a,b) (((a)>(b))?(a):(b))
#define kTestFlightAPIKey @"52ea4c59079a890422488d9748b00b72_OTE5NDkyMDEyLTA3LTI3IDE3OjA1OjE1LjEyMTE1OA"
#define kImgurAPIKey @"ee66d23c163a5da80cf7a861dc2a3185"
CGFloat animatedDistance;
