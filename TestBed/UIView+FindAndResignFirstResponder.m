//
//  UIView+FindAndResignFirstResponder.m
//  Apex
//
//  Created by Josh Barrow on 9/13/11.
//  Copyright (c) 2011 - 2012 ConnectPoint Resolution Systems, Inc. All rights reserved.
//

#import "UIView+FindAndResignFirstResponder.h"

@implementation UIView (FindAndResignFirstResponder)

-(BOOL)findAndResignFirstResponder
{
    if ([self isFirstResponder]) {
        [self resignFirstResponder];
        return YES;     
    }
    for (UIView *subView in [self subviews]) {
        if ([subView findAndResignFirstResponder])
            return YES;
    }
    return NO;
}
@end
