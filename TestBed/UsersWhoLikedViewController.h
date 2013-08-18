//
//  UsersWhoLikedViewController.h
//  Jukaela
//
//  Created by Josh on 1/1/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaCollectionViewController.h"

@interface UsersWhoLikedViewController : JukaelaCollectionViewController <MBProgressHUDDelegate>

@property (strong, nonatomic) NSArray *usersArray;

@end
