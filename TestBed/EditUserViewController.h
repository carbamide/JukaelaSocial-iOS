//
//  EditUserViewController.h
//  Jukaela
//
//  Created by Josh Barrow on 5/20/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@import UIKit;
#import "JukaelaTableViewController.h"

@interface EditUserViewController : JukaelaTableViewController

@property (strong, nonatomic) UITextField *emailTextField;
@property (strong, nonatomic) UITextField *nameTextField;
@property (strong, nonatomic) UITextField *passwordConfirmTextField;
@property (strong, nonatomic) UITextField *passwordTextField;
@property (strong, nonatomic) UITextField *usernameTextField;
@property (strong, nonatomic) UITextView *profileTextView;

-(IBAction)cancel:(id)sender;

@end
