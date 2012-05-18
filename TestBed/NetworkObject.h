//
//  NetworkObject.h
//  Jukaela
//
//  Created by Josh Barrow on 5/16/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkObject : NSObject

+(void)performRequestWithUri:(NSString *)requestUri params:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *))completionBlock;

@end
