//
//  ClearLabelsCellView.m
//  ShadowedTableView
//
//  Created by Matt Gallagher on 2009/08/21.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//

#import "ClearLabelsCellView.h"

NSString * const kJKPrepareForReuseNotification = @"CPCallbacksTableViewCell_PrepareForReuse";

@implementation ClearLabelsCellView

@synthesize nameLabel;
@synthesize dateLabel;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	
	if (self) {
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 140, 15)];
        
        [nameLabel setTextAlignment:UITextAlignmentLeft];
        [nameLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setTag:8];
        
        [self addSubview:nameLabel];
        
        dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 80, 140, 15)];
        [dateLabel setTextAlignment:UITextAlignmentLeft];
        [dateLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
        [dateLabel setBackgroundColor:[UIColor clearColor]];
        [dateLabel setTag:8];
        
        [self addSubview:dateLabel];
        
        [[self imageView] addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld context:NULL];
        [[self textLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
		[[self nameLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        [[self dateLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        
	}
	
	return self;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
    
	self.textLabel.backgroundColor = [UIColor clearColor];
	self.detailTextLabel.backgroundColor = [UIColor clearColor];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [self imageView] && [keyPath isEqualToString:@"image"] && ([change objectForKey:NSKeyValueChangeOldKey] == nil || [change objectForKey:NSKeyValueChangeOldKey] == [NSNull null])) {
        [self setNeedsLayout];
        [[self imageView] removeObserver:self forKeyPath:@"image"];
    }
}

-(void)prepareForReuse
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kJKPrepareForReuseNotification object:self];
	
    [[self imageView] setImage:nil];
    
	[super prepareForReuse];
}

-(void)dealloc
{
    @try {
        if (![[self imageView] image]) {
            [[self imageView] removeObserver:self forKeyPath:@"image"];
            [[self nameLabel] removeObserver:self forKeyPath:@"image"];
            [[self textLabel] removeObserver:self forKeyPath:@"image"];
            [[self dateLabel] removeObserver:self forKeyPath:@"image"];
        }
    }
    @catch (id anException) {
        NSLog(@"Trying to remove an observer when none was attached.");
    }
    
    [super dealloc];
}

@end
