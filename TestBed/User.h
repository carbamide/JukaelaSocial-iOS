//
//  User.h
//  Jukaela
//
//  Created by Josh on 8/15/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

@import Foundation;

@interface User : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *userId;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSDate *createdAt;
@property (strong, nonatomic) NSString *profile;
@property (strong, nonatomic) NSDate *updatedAt;

@property (nonatomic) BOOL sendEmail;
@property (nonatomic) BOOL isAdmin;

@end
