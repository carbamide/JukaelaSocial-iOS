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

-(void)getFeedFrom:(int)from to:(int)to;

@end
