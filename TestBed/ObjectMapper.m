//
//  ObjectMapper.m
//  Jukaela
//
//  Created by Josh on 8/15/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "ObjectMapper.h"
#import "FeedItem.h"
#import "User.h"

@implementation ObjectMapper

+(User *)convertToUserObject:(NSData *)json
{
    return (User *)nil;
}

+(NSArray *)convertToFeedItemObject:(NSData *) json
{
    NSMutableArray *returnArray = [NSMutableArray array];
    
    NSError *error = nil;
    
    NSArray *tempArray = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
    
    for (NSDictionary *tempDict in tempArray) {
        FeedItem *tempFeedItem = [[FeedItem alloc] init];
        
        [tempFeedItem setPostId:[self nullOrValue:tempDict[kID]]];
        [tempFeedItem setImageUrl:[NSURL URLWithString:[self nullOrValue:tempDict[kImageURL]]]];
        [tempFeedItem setContent:tempDict[kContent]];
        [tempFeedItem setCreatedAt:[NSDate dateWithISO8601String:[self nullOrValue:tempDict[kCreationDate]] withFormatter:[kAppDelegate dateFormatter]]];
        [tempFeedItem setRepostUserId:[self nullOrValue:tempDict[kRepostUserID]]];
        [tempFeedItem setOriginalPosterId:[self nullOrValue:tempDict[kOriginalPosterID]]];
        [tempFeedItem setRepostName:[self nullOrValue:tempDict[kRepostName]]];
        
        User *tempUser = [[User alloc] init];
        
        [tempUser setName:[self nullOrValue:tempDict[kName]]];
        [tempUser setUserId:[self nullOrValue:tempDict[kUserID]]];
        [tempUser setUsername:[self nullOrValue:tempDict[kUsername]]];
        [tempUser setEmail:[self nullOrValue:tempDict[kEmail]]];
        
        [tempFeedItem setUser:tempUser];
        
        [returnArray addObject:tempFeedItem];
    }
    
    return returnArray;
}

+(instancetype)nullOrValue:(id)value
{
    if (!value || value == [NSNull null]) {
        return nil;
    }
    
    return value;
}

@end
