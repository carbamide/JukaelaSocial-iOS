//
//  ActivityManager.h
//  Jukaela
//
//  Created by Josh on 12/22/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@import UIKit;

@interface ActivityManager : NSObject

@property (nonatomic) int count;
@property (assign) dispatch_queue_t queue;

+(id)sharedManager;

-(void)incrementActivityCount;
-(void)decrementActivityCount;

@end
