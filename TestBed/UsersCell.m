//
//  UsersCell
//  Jukaela Social
//
//  Created by Josh Barrow on 09/09/2012.
//  Copyright 2012 Josh Barrow. All rights reserved.
//

#import "Constants.h"
#import "AppDelegate.h"
#import "UsersCell.h"

NSString * const kJKPrepareForReuseNotification2 = @"CPCallbacksTableViewCell_PrepareForReuse2";

@implementation UsersCell

@synthesize contentText;
@synthesize disabled;
@synthesize tapGesture;
@synthesize longPressGesture;
@synthesize imageTapGesture;
@synthesize repostedNameLabel;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	
	if (self) {
        contentText = [[JSCoreTextView alloc] initWithFrame:CGRectMake(80, 17, 200, 25)];
        [contentText setBackgroundColor:[UIColor clearColor]];
        [contentText setClipsToBounds:YES];
        [contentText setPaddingTop:5];
        [contentText setUserInteractionEnabled:YES];
        
        [[self contentView] addSubview:contentText];
        
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
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [[self imageView] setBounds:CGRectMake(5, 7, 65, 65)];
    [[self imageView] setFrame:CGRectMake(5, 7, 65, 65)];
    [[self imageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    CGRect rect = self.imageView.frame;
    
    [[[self imageView] layer] setShadowOffset:CGSizeMake(0, 3)];
    [[[self imageView] layer] setShadowColor:[[UIColor lightGrayColor] CGColor]];
    [[[self imageView] layer] setShadowRadius:5];
    [[[self imageView] layer] setShadowOpacity:0.8];
    
    [[[self imageView] layer] setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8, 8)] CGPath]];
    
    [[self detailTextLabel] setFrame:CGRectMake(80, 19, 150, 76)];
    [[self detailTextLabel] setBackgroundColor:[UIColor clearColor]];
    
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
	[[NSNotificationCenter defaultCenter] postNotificationName:kJKPrepareForReuseNotification2 object:self];
	
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
