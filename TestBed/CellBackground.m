//
//  CellBackground.m
//  Jukaela Social
//
//  Created by Josh Barrow on 12/7/2012
//  Copyright 2012 Josh Barrow. All rights reserved.
//

#import "CellBackground.h"


@implementation CellBackground

+(Class)layerClass
{
	return [CAGradientLayer class];
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
	if (self)
	{
        UIImageView *anImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 2)];
        
        [anImageView setImage:[UIImage imageNamed:@"separator"]];
        [anImageView setAlpha:0.7];
        
        [self addSubview:anImageView];
        
        [anImageView release];
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    }
    
    return self;
}

@end
