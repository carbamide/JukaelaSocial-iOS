//
//  ViewController.h
//  Jukaela Social
//
//  Created by Josh Barrow on 5/3/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JukaelaViewController.h"

@interface LoginViewController : JukaelaViewController <NSURLConnectionDelegate,UITextFieldDelegate, MBProgressHUDDelegate>

@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;

@property (strong, nonatomic) MBProgressHUD *progressHUD;

@property (strong, nonatomic) NSDictionary *loginDict;

@property (nonatomic) BOOL doNotLogin;

-(void)loginAction:(id)sender;

-(IBAction)showLoginTextFields:(id)sender;

@end
