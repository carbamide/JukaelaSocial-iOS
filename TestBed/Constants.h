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
#import "JukaelaCollectionViewController.h"
#import "JRefreshControl.h"
#import "NSDate+RailsDateParser.h"
#import "NSString+BackslashEscape.h"
#import "PrettyKit.h"
#import "RequestFactory.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Alpha.h"
#import "YIFullScreenScroll.h"

static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 308;
CGFloat animatedDistance;
static char *const kIndexPathAssociationKey = "Jukaela_index_path";

#define kAppDelegate (AppDelegate *)[[UIApplication sharedApplication] delegate]

//#define kSocialURL @"http://localhost:3000"
#define kSocialURL @"http://cold-planet-7717.herokuapp.com"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define kHelveticaLight @"Helvetica-Light"
#define kImageURL @"image_url"
#define kContent @"content"
#define kName @"name"
#define kUserID @"user_id"
#define kUsername @"username"
#define kRepostUserID @"repost_user_id"
#define kCreationDate @"created_at"
#define kEmail @"email"
#define kID @"id"
#define kOriginalPosterID @"original_poster_id"
#define kRepostName @"repost_name"

#define kDoubleTapNotification @"double_tap"
#define kSendToUserNotification @"send_to_user"
#define kRepostSendToUserNotifiation @"repost_send_to_user"
#define kChangeTypeNotification @"set_change_type"
#define kRefreshYourTablesNotification @"refresh_your_tables"
#define kSuccessfulTweetNotification @"tweet_successful"
#define kSuccessfulFacebookNotification @"facebook_successful"
#define kFacebookOrTwitterCurrentlySending @"facebook_or_twitter_sending"
#define kStopAnimatingActivityIndicator @"stop_animating"
#define kPostOnlyToJukaela @"just_to_jukaela"
#define kShowImage @"show_image"
#define kPostImage @"post_image"
#define kImageNotification @"image"
#define kIndexPath @"indexPath"
#define kEnableCellNotification @"enable_cell"

#define kShowPostView @"ShowPostView"
#define kShowUser @"ShowUser"
#define kShowReplyView @"ShowReplyView"
#define kShowRepostView @"ShowRepostView"
#define kShowCompose @"Compose"
#define kShowFeed @"ShowFeed"
#define kShowEditUser @"EditUser"
#define kShowSubmitFeedback @"SubmitFeedback"
#define kShowFollowing @"ShowFollowing"
#define kShowFollowers @"ShowFollowers"
#define kShowUserPosts @"ShowUserPosts"

#define kReadUsernameFromDefaultsPreference @"read_username_from_defaults"
#define kDeviceTokenPreference @"deviceToken"
#define kPostToTwitterPreference @"post_to_twitter"
#define kPostToFacebookPreference @"post_to_facebook"
#define kJukaelaSocialServiceName @"Jukaela Social"

#define jMIN(a,b) (((a)<(b))?(a):(b))
#define jMAX(a,b) (((a)>(b))?(a):(b))

#define kTestFlightAPIKey @"52ea4c59079a890422488d9748b00b72_OTE5NDkyMDEyLTA3LTI3IDE3OjA1OjE1LjEyMTE1OA"
#define kImgurAPIKey @"ee66d23c163a5da80cf7a861dc2a3185"
