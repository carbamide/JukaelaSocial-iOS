//
//  MentionItem.h
//  Jukaela
//
//  Created by Josh on 8/17/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MentionItem : NSObject

@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSDate *createdAt;
@property (strong, nonatomic) NSNumber *postId;
@property (strong, nonatomic) NSURL *imageUrl;
@property (strong, nonatomic) NSString *senderEmail;
@property (strong, nonatomic) NSString *senderName;
@property (strong, nonatomic) NSNumber *senderUserId;
@property (strong, nonatomic) NSString *senderUsername;
@property (strong, nonatomic) NSDate *updatedAt;
@property (strong, nonatomic) NSNumber *userId;

@end
