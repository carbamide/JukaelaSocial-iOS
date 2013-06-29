//
//  NormalWithImageCellView.m
//  Jukaela
//
//  Created by Josh on 9/18/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "Constants.h"

#import "NormalWithImageCellView.h"

@implementation NormalWithImageCellView

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIWindow *tempWindow = [kAppDelegate window];
        
        [self setExternalImage:[[UIImageView alloc] initWithFrame:CGRectMake(tempWindow.frame.size.width - 46, 5, 37, 37)]];
        
        [[self dateLabel] setFrame:CGRectMake(128, 5, 140, 15)];
        
        [self addSubview:[self externalImage]];
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
        [[self externalImage] addObserver:self forKeyPath:kImageNotification options:NSKeyValueObservingOptionOld context:NULL];
    }
}

-(void)tapAction:(UIGestureRecognizer *)aGesture
{
    NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowImage object:nil userInfo:@{kIndexPath : indexPath}];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [self externalImage] && [keyPath isEqualToString:kImageNotification] && (change[NSKeyValueChangeOldKey] == nil || change[NSKeyValueChangeOldKey] == [NSNull null])) {
        [[self externalImage] setNeedsLayout];
        
        [self setNeedsLayout];
        
        [[self externalImage] removeObserver:self forKeyPath:kImageNotification];
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(void)prepareForReuse
{
    [super prepareForReuse];

    [[self externalImage] setImage:nil];
}
@end
