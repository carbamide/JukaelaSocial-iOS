//
//  RequestFactory.m
//  Jukaela
//
//  Created by Josh on 12/19/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "RequestFactory.h"

@implementation RequestFactory

+(NSString *)directMessageRequestWithContent:(NSString *)content userID:(NSString *)userID username:(NSString *)username
{
    return [NSString stringWithFormat:@"{\"direct_message\": {\"content\":\"%@\", \"from_user_id\":%@}, \"username\" : \"%@\"}", content, userID, username];
}

+(NSString *)editUserRequestWithName:(NSString *)name username:(NSString *)username email:(NSString *)email password:(NSString *)password passwordConfirmation:(NSString *)passwordConfirmation profile:(NSString *)profile sendEmail:(NSNumber *)sendEmail
{
    return [NSString stringWithFormat:@"{\"user\": { \"name\":\"%@\",\"username\":\"%@\", \"email\":\"%@\", \"password\":\"%@\", \"password_confirmation\":\"%@\", \"profile\":\"%@\", \"send_email\": %@}}", name, username, email, password, passwordConfirmation, profile, sendEmail];
}

+(NSString *)loginRequestWithEmail:(NSString *)email password:(NSString *)password apns:(NSString *)apns
{
    return [NSString stringWithFormat:@"{ \"session\": {\"email\" : \"%@\", \"password\" : \"%@\", \"apns\": \"%@\"}}", email, password, apns];
}

+(NSString *)feedRequestFrom:(int)from to:(int)to
{
    return [NSString stringWithFormat:@"{\"first\" : \"%i\", \"last\" : \"%i\"}", from, to];
}

+(NSString *)createNewUserRequestWithName:(NSString *)name username:(NSString *)username email:(NSString *)email password:(NSString *)password passwordConfirmation:(NSString *)passwordConfirmation
{
    return [NSString stringWithFormat:@"{\"user\": { \"name\":\"%@\",\"username\":\"%@\", \"email\":\"%@\", \"password\":\"%@\", \"password_confirmation\":\"%@\"}}", name, username, email, password, passwordConfirmation];
}

+(NSString *)postRequestWithContent:(NSString *)content userID:(NSString *)userID imageURL:(NSString *)imageURL
{
    if (imageURL) {
        return [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@, \"image_url\": \"%@\"}", content, userID, imageURL];
    }
    else {
        return [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", content, userID];
    }
}

+(NSString *)unfollowRequestWithUserID:(NSNumber *)userID
{
    return [NSString stringWithFormat:@"{\"commit\" : \"Unfollow\", \"id\" : \"%@\"}", userID];
}

+(NSString *)followRequestWithUserID:(NSNumber *)userID
{
    return [NSString stringWithFormat:@"{\"relationship\" : {\"followed_id\" : \"%@\"}, \"commit\" : \"Follow\"}", userID];
}

+(NSString *)userFromUsername:(NSString *)username
{
    return [NSString stringWithFormat:@"{\"username\" : \"%@\"}", username];
}

@end
