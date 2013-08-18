//
//  ApiFactory.m
//  Jukaela
//
//  Created by Josh on 8/15/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "ApiFactory.h"
#import "Constants.h"
#import "ObjectMapper.h"
#import "SFHFKeychainUtils.h"

@implementation ApiFactory

+ (instancetype)sharedManager
{
    static ApiFactory *sharedManager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

-(void)login
{
    [[ActivityManager sharedManager] incrementActivityCount];
    
    NSError *error = nil;
    
    NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:kUsername];
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:kJukaelaSocialServiceName error:&error];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/sessions.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory loginRequestWithEmail:username password:password apns:[[NSUserDefaults standardUserDefaults] valueForKey:kDeviceTokenPreference]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"logged_in" object:nil userInfo:@{@"loginUser": [ObjectMapper convertToUserObject:data]}];
        }
    }];
    
}
-(void)getFeedFrom:(int)from to:(int)to
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory feedRequestFrom:from to:to];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoadedFeed object:nil userInfo:@{@"feed": [ObjectMapper convertToFeedItemArray:data]}];
        }
    }];
}

-(void)getMentions
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/pages/mentions.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory feedRequestFrom:0 to:20];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        if (data) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loaded_mentions" object:nil userInfo:@{@"feed": [ObjectMapper convertToMentionItemArray:data]}];
        }
    }];
}

-(void)likePost:(NSNumber *)postId
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@/like.json", kSocialURL, postId]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"liked_post" object:nil];
    }];
}

-(void)showThreadForPost:(NSNumber *)postId
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@/thread_for_micropost.json", kSocialURL, postId]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"thread_for_micropost" object:nil userInfo:@{@"thread": [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]}];
    }];
}

-(void)deletePost:(NSNumber *)postId
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, postId]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"DELETE"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"deleted_post" object:nil userInfo:nil];

    }];
}

-(void)showImage:(NSURL *)imageUrl
{
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:imageUrl];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"show_image_opener" object:nil userInfo:@{@"data": data}];
    }];
}
@end
