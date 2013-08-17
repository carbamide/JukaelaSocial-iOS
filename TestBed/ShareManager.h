//
//  ShareObject.h
//  Jukaela
//
//  Created by Josh on 9/11/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedViewController.h"
#import "NormalCellView.h"

@interface ShareManager : NSObject

+(void)shareToTwitter:(NSString *)stringToSend withViewController:(FeedViewController *)feedViewController;
+(void)shareToFacebook:(NSString *)stringToSend withViewController:(FeedViewController *)feedViewController;
+(void)repost:(NSIndexPath *)indexPathOfCell fromArray:(NSArray *)theArray withViewController:(FeedViewController *)viewController;

@end
