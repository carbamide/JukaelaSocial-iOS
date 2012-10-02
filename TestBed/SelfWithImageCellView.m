//
//  SelfWithImageCellView.m
//  Jukaela
//
//  Created by Josh on 9/18/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "SelfWithImageCellView.h"

@implementation SelfWithImageCellView

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setExternalImage:[[UIImageView alloc] initWithFrame:CGRectMake(12, 25, 50, 50)]];
                
        [self addSubview:[self externalImage]];
        
        _externalActivityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(15, 35, 30, 30)];
        
        [[self externalActivityIndicator] setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        
        [self addSubview:_externalActivityIndicator];
        
        [[self contentText] setFrame:CGRectMake(60, 17, 185, 140)];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
        
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    
    [[self externalImage] setUserInteractionEnabled:YES];
    
    [[self externalImage] addGestureRecognizer:tapGesture];
        
    if (![[self externalImage] image]) {
        [[self externalImage] addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld context:NULL];
    }
    
    if ([[self externalImage] image]) {
        [[self externalActivityIndicator] stopAnimating];
    }
}

-(void)tapAction:(UIGestureRecognizer *)aGesture
{
    NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"show_image" object:nil userInfo:@{@"indexPath" : indexPath}];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [self externalImage] && [keyPath isEqualToString:@"image"] && (change[NSKeyValueChangeOldKey] == nil || change[NSKeyValueChangeOldKey] == [NSNull null])) {
        [[self externalImage] setNeedsLayout];
        
        [self setNeedsLayout];
        
        [[self externalImage] removeObserver:self forKeyPath:@"image"];
        
        if ([[self externalActivityIndicator] isAnimating]) {
            [[self externalActivityIndicator] stopAnimating];
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
