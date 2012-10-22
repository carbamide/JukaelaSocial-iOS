//
//  NetworkActivityIndicatorManager.h
//  Jukaela Social
//
//  Created by Josh Barrow on 10/15/2012.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkActivityIndicatorManager : NSObject

@property (assign) BOOL enabled;

+(NetworkActivityIndicatorManager *)sharedManager;

-(void)incrementActivityCount;
-(void)decrementActivityCount;

@end
