//
//  DataManager.h
//  Jukaela
//
//  Created by Josh on 8/25/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataManager : NSObject

+(instancetype)sharedInstance;

@property (strong, nonatomic) NSMutableArray *feedDataSource;
@property (strong, nonatomic) NSMutableArray *mentionsDataSource;

-(void)setFeedDataSource:(NSMutableArray *)feedDataSource;
-(void)setMentionsDataSource:(NSMutableArray *)mentionsDataSource;

@end
