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
        UIImageView *anImageView = nil;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            anImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 768, 2)];
        }
        else {
            anImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 2)];
        }
        
        [anImageView setImage:[UIImage imageNamed:@"separator"]];
        [anImageView setAlpha:0.7];
        
        [self addSubview:anImageView];
    }
    
    return self;
}

@end
