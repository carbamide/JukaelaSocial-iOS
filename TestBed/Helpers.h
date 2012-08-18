//
//  Helpers.h
//  Claims Express
//
//  Created by Josh on 8/26/11.
//  Copyright (c) 2011 - 2012 ConnectPoint Resolution Systems, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface Helpers : NSObject

+(void)moveViewUpFromTextField:(UITextField *)aTextField withView:(UIView *)aView;
+(void)moveViewDown:(UIView *)aView;
+(void)saveImage:(UIImage *)image withFileName:(NSString *)emailAddress;

+(NSMutableURLRequest *)getRequestWithURL:(NSURL *)url;
+(NSMutableURLRequest *)postRequestWithURL:(NSURL *)url withData:(NSData *)data;

+(void)errorAndLogout:(UIViewController *)aViewController withMessage:(NSString *)aMessage;

@end
