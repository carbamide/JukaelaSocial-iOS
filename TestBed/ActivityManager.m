//
//  ActivityManager.m
//  Jukaela
//
//  Created by Josh on 12/22/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "ActivityManager.h"

@implementation ActivityManager

+ (id)sharedManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
    if (self = [super init]) {
        _count = 0;
        
        [self setQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    return self;
}

-(void)updateActivityDisplay
{
    if(_count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    }
    
    NSLog(@"The current network activity indicator count is %d", _count);
}

-(void)incrementActivityCount
{
    dispatch_async([self queue], ^{
        _count++;
        
        [self updateActivityDisplay];
    });
}

-(void)decrementActivityCount
{
    dispatch_async([self queue], ^{
        if(_count > 0) {
            _count--;
        }
        
        [self updateActivityDisplay];
    });
}

@end
