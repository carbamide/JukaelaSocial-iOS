//
//  JukaelaTableViewProtocol.h
//  Jukaela
//
//  Created by Josh on 8/16/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

@import Foundation;

@protocol JukaelaTableViewProtocol <NSObject>

-(void)tapHandler:(NSNotification *)aNotification;
-(void)showImageHandler:(NSNotification *)aNotification;
-(void)tappedUserHandler:(NSNotification *)aNotification;
-(void)requestWithUsername:(NSString *)username;

@end
