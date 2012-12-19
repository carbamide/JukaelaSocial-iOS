//
//  JRefreshControl.m
//  Jukaela
//
//  Created by Josh on 12/18/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JRefreshControl.h"

@implementation JRefreshControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(void)layoutSubviews
{
    UIScrollView *parentScrollView = (UIScrollView*)[self superview];
    
    CGSize viewSize = parentScrollView.frame.size;
    
    if (parentScrollView.contentInset.top + parentScrollView.contentOffset.y == 0 && !self.refreshing) {
        [self setHidden:YES];
    }
    else {
        [self setHidden:NO];
    }
    
    if ([self isRefreshing]) {
        [self setFrame:CGRectOffset(self.frame, 0, 44)];
    }
    else {
        [self setFrame:CGRectMake(0, -90, viewSize.width, viewSize.height)];
    }
    
    [super layoutSubviews];
}

-(void)beginRefreshing
{
    
    [super beginRefreshing];
}

@end
