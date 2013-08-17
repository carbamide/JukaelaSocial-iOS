//
//  Constants.h
//  Jukaela Social
//
//  Created by Josh Barrow on 5/4/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import "ActivityManager.h"
#import "AppDelegate.h"
#import "Helpers.h"
#import "JukaelaViewController.h"
#import "JukaelaTableViewController.h"
#import "JukaelaCollectionViewController.h"
#import "NSDate+RailsDateParser.h"
#import "NSString+BackslashEscape.h"
#import "RequestFactory.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Alpha.h"
#import "RIButtonItem.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "UIImage+ImageEffects.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"

static CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 308;
CGFloat animatedDistance;

static char *kIndexPathAssociationKey = "Jukaela_index_path";

static NSString *kSocialURL= @"http://cold-planet-7717.herokuapp.com";

static NSString *kHelveticaLight = @"Helvetica-Light";

static NSString *kImageURL = @"image_url";
static NSString *kContent = @"content";
static NSString *kName = @"name";
static NSString *kUserID = @"user_id";
static NSString *kUsername = @"username";
static NSString *kRepostUserID = @"repost_user_id";
static NSString *kCreationDate = @"created_at";
static NSString *kEmail = @"email";
static NSString *kID = @"id";
static NSString *kOriginalPosterID = @"original_poster_id";
static NSString *kRepostName = @"repost_name";

static NSString *kTapNotification = @"double_tap";
static NSString *kSendToUserNotification = @"send_to_user";
static NSString *kRepostSendToUserNotifiation = @"repost_send_to_user";
static NSString *kChangeTypeNotification = @"set_change_type";
static NSString *kRefreshYourTablesNotification = @"refresh_your_tables";
static NSString *kSuccessfulTweetNotification = @"tweet_successful";
static NSString *kSuccessfulFacebookNotification = @"facebook_successful";
static NSString *kFacebookOrTwitterCurrentlySending = @"facebook_or_twitter_sending";
static NSString *kStopAnimatingActivityIndicator = @"stop_animating";
static NSString *kPostOnlyToJukaela = @"just_to_jukaela";
static NSString *kShowImage = @"show_image";
static NSString *kPostImage = @"post_image";
static NSString *kImageNotification = @"image";
static NSString *kIndexPath = @"indexPath";
static NSString *kEnableCellNotification = @"enable_cell";
static NSString *kJukaelaSuccessfulNotification = @"jukaela_successful";
static NSString *kLoadUserWithUsernameNotification = @"user_with_username";

static NSString *kShowPostView = @"ShowPostView";
static NSString *kShowUser = @"ShowUser";
static NSString *kShowReplyView = @"ShowReplyView";
static NSString *kShowRepostView = @"ShowRepostView";
static NSString *kShowCompose = @"Compose";
static NSString *kShowFeed = @"ShowFeed";
static NSString *kShowEditUser = @"EditUser";
static NSString *kShowSubmitFeedback = @"SubmitFeedback";
static NSString *kShowFollowing = @"ShowFollowing";
static NSString *kShowFollowers = @"ShowFollowers";
static NSString *kShowUserPosts = @"ShowUserPosts";
static NSString *kShowThread = @"ShowThread";

static NSString *kReadUsernameFromDefaultsPreference = @"read_username_from_defaults";
static NSString *kDeviceTokenPreference = @"deviceToken";
static NSString *kPostToTwitterPreference = @"post_to_twitter";
static NSString *kPostToFacebookPreference = @"post_to_facebook";
static NSString *kJukaelaSocialServiceName = @"Jukaela Social";


static NSString *kTestFlightAPIKey = @"52ea4c59079a890422488d9748b00b72_OTE5NDkyMDEyLTA3LTI3IDE3OjA1OjE1LjEyMTE1OA";
static NSString *kImgurAPIKey = @"ee66d23c163a5da80cf7a861dc2a3185";

static NSString *kLoadedFeed = @"loaded_feed";

#pragma clang diagnostic pop

#define kAppDelegate (AppDelegate *)[[UIApplication sharedApplication] delegate]
#define COLOR_RGB(r,g,b,a)      [UIColor colorWithRed:((r)/255.0) green:((g)/255.0) blue:((b)/255.0) alpha:(a)]
#define kFontPreference [[NSUserDefaults standardUserDefaults] valueForKey:@"font_preference"] ? [[NSUserDefaults standardUserDefaults] valueForKey:@"font_preference"] : kHelveticaLight
#define jMIN(a,b) (((a)<(b))?(a):(b))
#define jMAX(a,b) (((a)>(b))?(a):(b))
