//
//  Helpers.h
//  Claims Express
//
//  Created by Josh on 8/26/11.
//  Copyright (c) 2011 - 2012 ConnectPoint Resolution Systems, Inc. All rights reserved.
//

@import Foundation;
#import "Constants.h"

@interface Helpers : NSObject

+(void)errorAndLogout:(UIViewController *)aViewController withMessage:(NSString *)aMessage;

+(UIImage *)loginImage;

@end
