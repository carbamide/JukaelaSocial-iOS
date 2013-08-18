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
#import "MentionItem.h"
#import "NSDate+RailsDateParser.h"

@implementation ObjectMapper

+(User *)convertToUserObject:(NSData *)json
{
    NSError *error = nil;
    
    NSDictionary *tempDict = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
    
    User *tempUser = [[User alloc] init];
    
    [tempUser setName:[self nullOrValue:tempDict[kName]]];
    [tempUser setUserId:[self nullOrValue:tempDict[kID]]];
    [tempUser setUsername:[self nullOrValue:tempDict[kUsername]]];
    [tempUser setEmail:[self nullOrValue:tempDict[kEmail]]];
    [tempUser setCreatedAt:[NSDate dateWithISO8601String:[self nullOrValue:tempDict[kCreationDate]] withFormatter:[kAppDelegate dateFormatter]]];
    [tempUser setUpdatedAt:[NSDate dateWithISO8601String:[self nullOrValue:tempDict[@"updated_at"]] withFormatter:[kAppDelegate dateFormatter]]];
    [tempUser setProfile:[self nullOrValue:tempDict[@"profile"]]];
    [tempUser setSendEmail:[(NSNumber *)tempDict[@"send_email"] boolValue]];
    [tempUser setIsAdmin:[(NSNumber *)tempDict[@"admin"] boolValue]];
    
    return tempUser;
}

+(NSArray *)convertToFeedItemArray:(NSData *)json
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
        [tempFeedItem setUsersWhoLiked:[self nullOrValue:tempDict[@"users_who_liked"]]];
        [tempFeedItem setInReplyTo:[self nullOrValue:tempDict[@"in_reply_to"]]];
        
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

+(NSArray *)convertToMentionItemArray:(NSData *)json
{
    NSMutableArray *returnArray = [NSMutableArray array];
    
    NSError *error = nil;
    
    NSArray *tempArray = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
    
    for (NSDictionary *tempDict in tempArray) {
        MentionItem *tempItem = [[MentionItem alloc] init];
        
        [tempItem setContent:tempDict[kContent]];
        [tempItem setCreatedAt:[NSDate dateWithISO8601String:[self nullOrValue:tempDict[kCreationDate]] withFormatter:[kAppDelegate dateFormatter]]];
        [tempItem setPostId:[self nullOrValue:tempDict[kID]]];
        [tempItem setImageUrl:[NSURL URLWithString:[self nullOrValue:tempDict[kImageURL]]]];
        [tempItem setSenderEmail:[self nullOrValue:tempDict[@"sender_email"]]];
        [tempItem setSenderName:[self nullOrValue:tempDict[@"sender_name"]]];
        [tempItem setSenderUserId:[self nullOrValue:tempDict[@"sender_user_id"]]];
        [tempItem setSenderUsername:[self nullOrValue:tempDict[@"sender_username"]]];
        [tempItem setUpdatedAt:[NSDate dateWithISO8601String:[self nullOrValue:tempDict[@"updated_at"]] withFormatter:[kAppDelegate dateFormatter]]];
        [tempItem setUserId:[self nullOrValue:tempDict[@"user_id"]]];
        
        [returnArray addObject:tempItem];
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
