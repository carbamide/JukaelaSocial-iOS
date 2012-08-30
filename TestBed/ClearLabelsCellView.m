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
@synthesize usernameLabel;
@synthesize contentText;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	
	if (self) {
        contentText = [[JTextView alloc] initWithFrame:CGRectMake(82, 17, 235, 140)];
        [contentText setEditable:NO];
        [contentText setDataDetectorTypes:UIDataDetectorTypeLink];
        [contentText setBackgroundColor:[UIColor clearColor]];
        [contentText setClipsToBounds:YES];
        
        [[self contentView] addSubview:contentText];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        [tapGesture setNumberOfTapsRequired:2];
        
        [contentText addGestureRecognizer:tapGesture];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        
        [contentText addGestureRecognizer:longPressGesture];
        
        [longPressGesture release];
        [tapGesture release];
        
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(90, 5, 140, 15)];
        
        [nameLabel setTextAlignment:NSTextAlignmentLeft];
        [nameLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14]];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setTag:8];
        
        [self addSubview:nameLabel];
        
        dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 5, 80, 140, 15)];
        [dateLabel setTextAlignment:NSTextAlignmentCenter];
        [dateLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
        [dateLabel setBackgroundColor:[UIColor clearColor]];
        [dateLabel setTag:8];
        
        [self addSubview:dateLabel];
        
        usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 5, 140, 15)];
        [usernameLabel setTextAlignment:NSTextAlignmentRight];
        [usernameLabel setFont:[UIFont fontWithName:@"Helvetica" size:14]];
        [usernameLabel setBackgroundColor:[UIColor clearColor]];
        [usernameLabel setTextColor:[UIColor darkGrayColor]];
        [usernameLabel setTag:8];
        [usernameLabel sizeToFit];
        
        [self addSubview:usernameLabel];
        
        [[self imageView] addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld context:NULL];
        [[self textLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
		[[self nameLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        [[self dateLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        [[self usernameLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        
        [[self imageView] setUserInteractionEnabled:YES];
        
        UITapGestureRecognizer *imageTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendToUser:)];
        
        [[self imageView] addGestureRecognizer:imageTapGesture];
        
        [imageTapGesture release];
	}
	
	return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [[self imageView] setBounds:CGRectMake(7, 0, 75, 75)];
    [[self imageView] setFrame:CGRectMake(7, 0, 75, 75)];
    [[self imageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    [[self textLabel] setFrame:CGRectMake(90, 25, 215, 140)];
    [[self textLabel] setNumberOfLines:0];
    [[self textLabel] sizeToFit];
    [[self textLabel] setHidden:YES];
    
    [[self usernameLabel] setFrame:CGRectMake(self.frame.size.width - self.usernameLabel.frame.size.width - 5, 5, 140, 15)];
    
    [[self detailTextLabel] setFrame:CGRectMake(90, 25, 150, 76)];
    
    [[self dateLabel] sizeToFit];
    
    [[self dateLabel] setCenter:[[self imageView] center]];
    
    [[self dateLabel] setFrame:CGRectMake(self.dateLabel.frame.origin.x, self.imageView.frame.origin.y + self.imageView.frame.size.height, self.dateLabel.frame.size.width, self.dateLabel.frame.size.height)];
    
    if (![[self imageView] image]) {
        [[self imageView] addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld context:NULL];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
    
    [[self textLabel] setBackgroundColor:[UIColor clearColor]];
    [[self detailTextLabel] setBackgroundColor:[UIColor clearColor]];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [self imageView] && [keyPath isEqualToString:@"image"] && (change[NSKeyValueChangeOldKey] == nil || change[NSKeyValueChangeOldKey] == [NSNull null])) {
        [[self imageView] setNeedsLayout];
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
        }
        
        if (![[self nameLabel] text]) {
            [[self nameLabel] removeObserver:self forKeyPath:@"text"];
        }
        
        if (![[self textLabel] text]) {
            [[self textLabel] removeObserver:self forKeyPath:@"text"];
        }
        
        if (![[self dateLabel] text]) {
            [[self dateLabel] removeObserver:self forKeyPath:@"text"];
        }
        
        if (![[self usernameLabel] text]) {
            [[self usernameLabel] removeObserver:self forKeyPath:@"text"];
        }
    }
    @catch (id anException) {
        NSLog(@"Trying to remove an observer when none was attached.");
    }
    
    [super dealloc];
}

-(void)doubleTapAction:(UIGestureRecognizer *)gesture
{
    if([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
        if(UIGestureRecognizerStateBegan == gesture.state) {
            NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"double_tap" object:nil userInfo:@{@"indexPath" : indexPath}];
        }
    }
    else {
        NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"double_tap" object:nil userInfo:@{@"indexPath" : indexPath}];
    }
}

-(void)sendToUser:(UIGestureRecognizer *)gesture
{
    NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"send_to_user" object:nil userInfo:@{@"indexPath" : indexPath}];
    
}

@end
