//
//  JukaelaTextView.h
//  Jukaela
//
//  Created by Josh on 8/20/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JukaelaTextView : UITextView

@property (strong, nonatomic) NSString *placeholder;
@property (strong, nonatomic) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end
