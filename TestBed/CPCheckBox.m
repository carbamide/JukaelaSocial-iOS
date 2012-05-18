//
//  CPCheckBox.m
//  Apex (Reused from Pitch Gauge) (Reused from STEEP)
//
//  Created by Josh Barrow on 8/6/11.
//  Copyright 2011 - 2012 ConnectPoint Resolution Systems, Inc. All rights reserved.
//

#import "CPCheckBox.h"

@implementation CPCheckBox
@synthesize isChecked;

-(id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) {
        [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];

		[self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];
		[self addTarget:self action:@selector(checkBoxClicked) forControlEvents:UIControlEventTouchUpInside];
	}
    return self;
}

-(IBAction)checkBoxClicked
{
    if([self isChecked] == NO) {
        [self setIsChecked:YES];
		[self setImage:[UIImage imageNamed:@"checkbox_ticked.png"] forState:UIControlStateNormal];
	}
    else {
        [self setIsChecked:NO];
		[self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];
	}

}

-(void)setChecked
{
    if([self isChecked] == NO) {
        [self setIsChecked:YES];
		[self setImage:[UIImage imageNamed:@"checkbox_ticked.png"] forState:UIControlStateNormal];
	}
    else {
        [self setIsChecked:NO];
		[self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];
	}
}

@end
