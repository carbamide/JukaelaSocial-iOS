//
//  ApiFactory.h
//  Jukaela
//
//  Created by Josh on 8/15/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

@import Foundation;

@class User;

@interface ApiFactory : NSObject <NSURLConnectionDelegate>

+(instancetype)sharedManager;

-(void)login;
-(void)getFeedFrom:(int)from to:(int)to;
-(void)likePost:(NSNumber *)postId;
-(void)showThreadForPost:(NSNumber *)postId;
-(void)deletePost:(NSNumber *)postId;
-(void)showImage:(NSURL *)imageUrl;
-(void)getMentions;
-(void)loginImage;
-(void)getCurrentUser;
-(void)updateUser:(User *)user password:(NSString *)password;
-(void)createNewUser:(User *)user password:(NSString *)password;

@end
