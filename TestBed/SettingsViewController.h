//
//  SettingsViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@import UIKit;
#import "JukaelaTableViewController.h"

@interface SettingsViewController : JukaelaTableViewController <UIPickerViewDataSource, UIPickerViewDelegate>

-(void)logOut:(id)sender;

@end
