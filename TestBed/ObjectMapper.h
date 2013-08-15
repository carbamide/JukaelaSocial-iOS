//
//  ObjectMapper.h
//  Jukaela
//
//  Created by Josh on 8/15/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;
@class FeedItem;

@interface ObjectMapper : NSObject

+(User *)convertToUserObject:(NSData *)json;
+(FeedItem *)convertToFeedItemObject:(NSData *) json;
@end
