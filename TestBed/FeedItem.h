//
//  FeedItem.h
//  Jukaela
//
//  Created by Josh on 8/14/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface FeedItem : NSObject

@property (strong, nonatomic) NSNumber *postId;
@property (strong, nonatomic) NSURL *imageUrl;
@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSDate *createdAt;
@property (strong, nonatomic) NSNumber *repostUserId;
@property (strong, nonatomic) NSNumber *originalPosterId;
@property (strong, nonatomic) NSString *repostName;
@property (strong, nonatomic) User *user;

@end
