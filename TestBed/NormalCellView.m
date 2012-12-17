//
//  NormalCellView.m
//  Jukaela Social
//
//  Created by Josh Barrow on 09/09/2012.
//  Copyright 2012 Josh Barrow. All rights reserved.
//

#import "Constants.h"
#import "AppDelegate.h"
#import "NormalCellView.h"

NSString * const kJKPrepareForReuseNotification = @"CPCallbacksTableViewCell_PrepareForReuse2";

@implementation NormalCellView

@synthesize nameLabel;
@synthesize dateLabel;
@synthesize usernameLabel;
@synthesize contentText;
@synthesize disabled;
@synthesize tapGesture;
@synthesize longPressGesture;
@synthesize imageTapGesture;
@synthesize repostedNameLabel;
@synthesize repostTapGesture;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	
	if (self) {
        contentText = [[JSCoreTextView alloc] initWithFrame:CGRectMake(0, 50, 315, 140)];
        [contentText setBackgroundColor:[UIColor clearColor]];
        [contentText setClipsToBounds:YES];
        [contentText setPaddingLeft:8];
        [contentText setPaddingTop:5];
        [contentText setUserInteractionEnabled:YES];
        
        [[self contentView] addSubview:contentText];
        
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(53, 9, 140, 15)];
        
        [nameLabel setTextAlignment:NSTextAlignmentLeft];
        [nameLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:18]];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setTag:8];
        
        [self addSubview:nameLabel];
        
        dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(175, 5, 140, 15)];
        [dateLabel setTextAlignment:NSTextAlignmentRight];
        [dateLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:14]];
        [dateLabel setBackgroundColor:[UIColor clearColor]];
        [dateLabel setTag:8];
        [dateLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
        
        [self addSubview:dateLabel];
        
        usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(53, 30, 140, 15)];
        [usernameLabel setTextAlignment:NSTextAlignmentLeft];
        [usernameLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:14]];
        [usernameLabel setBackgroundColor:[UIColor clearColor]];
        [usernameLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
        [usernameLabel setTag:8];
        [usernameLabel sizeToFit];
        
        [self addSubview:usernameLabel];
        
        repostedNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 90, 228, 20)];
        
        [repostedNameLabel setTextAlignment:NSTextAlignmentLeft];
        [repostedNameLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:12]];
        [repostedNameLabel setTextColor:[UIColor darkGrayColor]];
        [repostedNameLabel setBackgroundColor:[UIColor clearColor]];
        [repostedNameLabel setTag:8];
        [repostedNameLabel setUserInteractionEnabled:YES];
        
        [self addSubview:repostedNameLabel];
        
        [[self imageView] addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld context:NULL];
        [[self textLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
		[[self nameLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        [[self dateLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        [[self usernameLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        [[self repostedNameLabel] addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld context:NULL];
        
        [[self imageView] setUserInteractionEnabled:YES];
        
        [self createGestureRecognizers];
    }
	
	return self;
}

-(void)createGestureRecognizers
{
    if (![self longPressGesture]) {
        longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        
        [contentText addGestureRecognizer:longPressGesture];
    }
    
    if (![self imageTapGesture]) {
        imageTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendToUser:)];
        
        [[self imageView] addGestureRecognizer:imageTapGesture];
    }
    
    if (![self repostTapGesture]) {
        repostTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(repostSendToUser:)];
        
        [[self repostedNameLabel] addGestureRecognizer:repostTapGesture];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
        
    [[NSNotificationCenter defaultCenter] addObserverForName:@"enable_cell" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification){
        [self setDisabled:NO];
        
        [[self contentText] setAlpha:1.0];
        [[self imageView] setAlpha:1.0];
        [[self nameLabel] setAlpha:1.0];
        [[self textLabel] setAlpha:1.0];
        [[self dateLabel] setAlpha:1.0];
        [[self usernameLabel] setAlpha:1.0];
    }];
    
    [[self imageView] setBounds:CGRectMake(5, 5, 40, 40)];
    [[self imageView] setFrame:CGRectMake(5, 5, 40, 40)];
    [[self imageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    CGRect rect = self.imageView.frame;
    
    [[[self imageView] layer] setShadowOffset:CGSizeMake(0, 3)];
    [[[self imageView] layer] setShadowColor:[[UIColor lightGrayColor] CGColor]];
    [[[self imageView] layer] setShadowRadius:5];
    [[[self imageView] layer] setShadowOpacity:0.8];

    [[[self imageView] layer] setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8, 8)] CGPath]];

    [[self textLabel] setHidden:YES];
    
    [[self usernameLabel] setFrame:CGRectMake(53, 30, 140, 15)];
    
    [[self detailTextLabel] setFrame:CGRectMake(90, 25, 150, 76)];
        
    if (![[self imageView] image]) {
        [[self imageView] addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld context:NULL];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
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
    [[self repostedNameLabel] setText:nil];
    
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

-(void)repostSendToUser:(UIGestureRecognizer *)gesture
{
    NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"repost_send_to_user" object:nil userInfo:@{@"indexPath" : indexPath}];
}

-(void)disableCell
{
    float disabledAlpha = 0.439216;
    
    [self setDisabled:YES];
    
    [UIView animateWithDuration:0.4 animations:^(void) {
        [[self contentText] setAlpha:disabledAlpha];
        [[self imageView] setAlpha:disabledAlpha];
        [[self nameLabel] setAlpha:disabledAlpha];
        [[self textLabel] setAlpha:disabledAlpha];
        [[self dateLabel] setAlpha:disabledAlpha];
        [[self usernameLabel] setAlpha:disabledAlpha];
        
        [self setUserInteractionEnabled:YES];
    }];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}
@end
