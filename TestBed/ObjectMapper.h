//
//  ObjectMapper.h
//  Jukaela
//
//  Created by Josh on 8/15/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

@import Foundation;

@class User;
@class FeedItem;
@class LoginImage;

@interface ObjectMapper : NSObject

+(User *)convertToUserObject:(NSData *)json;
+(LoginImage *)convertToLoginImageObject:(NSData *)json;

+(NSArray *)convertToFeedItemArray:(NSData *)json;
+(NSArray *)convertToMentionItemArray:(NSData *)json;

@end
