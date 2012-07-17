//
//  SettingsViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController

@property (strong, nonatomic) UISwitch *facebookSwitch;
@property (strong, nonatomic) UISwitch *twitterSwitch;

-(void)logOut:(id)sender;

@end
