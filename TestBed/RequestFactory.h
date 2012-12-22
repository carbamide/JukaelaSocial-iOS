//
//  RequestFactory.h
//  Jukaela
//
//  Created by Josh on 12/19/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RequestFactory : NSObject

+(NSString *)directMessageRequestWithContent:(NSString *)content userID:(NSString *)userID username:(NSString *)username;
+(NSString *)editUserRequestWithName:(NSString *)name username:(NSString *)username email:(NSString *)email password:(NSString *)password passwordConfirmation:(NSString *)passwordConfirmation profile:(NSString *)profile sendEmail:(NSNumber *)sendEmail;
+(NSString *)loginRequestWithEmail:(NSString *)email password:(NSString *)password apns:(NSString *)apns;
+(NSString *)feedRequestFrom:(int)from to:(int)to;
+(NSString *)createNewUserRequestWithName:(NSString *)name username:(NSString *)username email:(NSString *)email password:(NSString *)password passwordConfirmation:(NSString *)passwordConfirmation;
+(NSString *)postRequestWithContent:(NSString *)content userID:(NSString *)userID imageURL:(NSString *)imageURL;
+(NSString *)unfollowRequestWithUserID:(NSNumber *)userID;
+(NSString *)followRequestWithUserID:(NSNumber *)userID;
+(NSString *)userFromUsername:(NSString *)username;

@end
