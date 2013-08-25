//
//  DataManager.m
//  Jukaela
//
//  Created by Josh on 8/25/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "DataManager.h"

@implementation DataManager

+ (instancetype)sharedInstance
{
    static DataManager *sharedManager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

@end
