//
//  TMNetworkActivityIndicatorManager.m
//  Jukaela Social
//
//  Created by Josh Barrow on 10/15/2012.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "NetworkActivityIndicatorManager.h"

@interface NetworkActivityIndicatorManager ()

@property (assign) dispatch_queue_t activityQueue;
@property (nonatomic) NSInteger count;
@end

@implementation NetworkActivityIndicatorManager

@synthesize enabled;
@synthesize activityQueue;


+(NetworkActivityIndicatorManager *)sharedManager
{
    static NetworkActivityIndicatorManager *shared = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        shared = [[NetworkActivityIndicatorManager alloc] init];
    });
    
    return shared;
}

-(id)init
{
    self = [super init];
    if (self) {
        _count = 0;
        [self setActivityQueue:dispatch_queue_create("com.jukaela.Jukaela", DISPATCH_QUEUE_SERIAL)];
        
        dispatch_set_target_queue([self activityQueue], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    }
    
    return self;
}

-(void)updateActivityDisplay
{
    if (_count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    }
}

-(void)incrementActivityCount
{
    dispatch_async([self activityQueue], ^{
        _count++;
        [self updateActivityDisplay];
    });
}

-(void)decrementActivityCount
{
    dispatch_async([self activityQueue], ^{
        if (_count > 0) {
            _count--;
        }
        [self updateActivityDisplay];
    });
}


@end
