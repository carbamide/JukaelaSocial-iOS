//
//  UsersCollectionViewCell.m
//  Jukaela
//
//  Created by Josh on 12/10/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "UsersCollectionViewCell.h"

@implementation UsersCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

-(void)prepareForReuse
{
    [[self usernameLabel] setText:nil];
    [[self textLabel] setText:nil];
    
    [[self imageView] setImage:nil];
    
    [super prepareForReuse];
}

@end
