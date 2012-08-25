//
//  JTextView.m
//  Jukaela
//
//  Created by Josh on 8/25/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JTextView.h"

@implementation JTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(BOOL)canBecomeFirstResponder
{
    return NO;
}

@end
