//
//  DirectMessagesViewController.h
//  Jukaela
//
//  Created by Josh on 12/9/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaTableViewController.h"

@interface DirectMessagesViewController : JukaelaTableViewController <UITableViewDataSource, UITableViewDelegate>

-(void)getMessages;

@end
