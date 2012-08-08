//
//  ViewController.h
//  TestBed
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "CPCheckBox.h"

@interface LoginViewController : JukaelaViewController <NSURLConnectionDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MBProgressHUDDelegate>
{
    NSDictionary *loginDict;
}

@property (strong, nonatomic) IBOutlet UITableView *loginTableView;
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) CPCheckBox *rememberUsername;
@property (strong, nonatomic) MBProgressHUD *progressHUD;

-(IBAction)loginAction:(id)sender;

@end
