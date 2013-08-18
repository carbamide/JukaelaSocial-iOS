//
//  ApiFactory.h
//  Jukaela
//
//  Created by Josh on 8/15/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApiFactory : NSObject <NSURLConnectionDelegate>

+(instancetype)sharedManager;

-(void)login;
-(void)getFeedFrom:(int)from to:(int)to;
-(void)likePost:(NSNumber *)postId;
-(void)showThreadForPost:(NSNumber *)postId;
-(void)deletePost:(NSNumber *)postId;
-(void)showImage:(NSURL *)imageUrl;
-(void)getMentions;

@end
