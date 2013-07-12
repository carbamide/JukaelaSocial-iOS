//
//  NormalCellView.m
//  Jukaela Social
//
//  Created by Josh Barrow on 09/09/2012.
//  Copyright 2012 Josh Barrow. All rights reserved.
//

#import "Constants.h"

#import "NormalCellView.h"

NSString * const kJKPrepareForReuseNotification = @"TableViewCell_PrepareForReuse2";

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
@synthesize postDate;
@synthesize dateTimer;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	
	if (self) {
        contentText = [[UITextView alloc] initWithFrame:CGRectMake(8, 45, 315, 170)];

        [contentText setBackgroundColor:[UIColor clearColor]];
        [contentText setClipsToBounds:YES];
        [contentText setUserInteractionEnabled:YES];
        [contentText setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
        [contentText setEditable:NO];
        [contentText setScrollsToTop:NO];
        [contentText setSelectable:NO];
        
        [[self contentView] addSubview:contentText];
        
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(53, 9, 140, 16)];
        
        [nameLabel setTextAlignment:NSTextAlignmentLeft];
        [nameLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setTag:8];
        
        [self addSubview:nameLabel];
        
        dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(175, 5, 140, 15)];
        
        [dateLabel setTextAlignment:NSTextAlignmentRight];
        [dateLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
        [dateLabel setBackgroundColor:[UIColor clearColor]];
        [dateLabel setTag:8];
        [dateLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
        
        [self addSubview:dateLabel];
        
        usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(53, 30, 140, 15)];
        [usernameLabel setTextAlignment:NSTextAlignmentLeft];
        [usernameLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
        [usernameLabel setBackgroundColor:[UIColor clearColor]];
        [usernameLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
        [usernameLabel setTag:8];
        [usernameLabel sizeToFit];
        
        [self addSubview:usernameLabel];
        
        repostedNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 90, 228, 20)];
        
        [repostedNameLabel setTextAlignment:NSTextAlignmentLeft];
        [repostedNameLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
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
        
        [self addGestureRecognizer:longPressGesture];
    }
    
    if (![self imageTapGesture]) {
        imageTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendToUser:)];
        
        [[self imageView] addGestureRecognizer:imageTapGesture];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [[NSNotificationCenter defaultCenter] addObserverForName:kEnableCellNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification){
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

    [[self textLabel] setHidden:YES];
    
    [[self usernameLabel] setFrame:CGRectMake(53, 30, 140, 15)];
    
    [[self detailTextLabel] setFrame:CGRectMake(90, 25, 150, 76)];
    
    if (![[self imageView] image]) {
        [[self imageView] addObserver:self forKeyPath:kImageNotification options:NSKeyValueObservingOptionOld context:NULL];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [self imageView] && [keyPath isEqualToString:kImageNotification] && (change[NSKeyValueChangeOldKey] == nil || change[NSKeyValueChangeOldKey] == [NSNull null])) {
        [[self imageView] setNeedsLayout];
        
        [self setNeedsLayout];
        
        [[self imageView] removeObserver:self forKeyPath:kImageNotification];
    }
}

-(void)prepareForReuse
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kJKPrepareForReuseNotification object:self];
	
    [[self imageView] setImage:nil];
    [[self repostedNameLabel] setText:nil];
    [[self dateTimer] invalidate];
    
	[super prepareForReuse];
}

-(void)dealloc
{
    @try {
        if (![[self imageView] image]) {
            [[self imageView] removeObserver:self forKeyPath:kImageNotification];
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
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDoubleTapNotification object:nil userInfo:@{kIndexPath : indexPath}];
        }
    }
    else {
        NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDoubleTapNotification object:nil userInfo:@{kIndexPath : indexPath}];
    }
}

-(void)sendToUser:(UIGestureRecognizer *)gesture
{
    NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSendToUserNotification object:nil userInfo:@{kIndexPath : indexPath}];
}

-(void)repostSendToUser:(UIGestureRecognizer *)gesture
{
    NSIndexPath *indexPath = [(UITableView *)[self superview] indexPathForCell:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRepostSendToUserNotifiation object:nil userInfo:@{kIndexPath : indexPath}];
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

-(void)setDate:(NSString *)date
{
    postDate = date;
    
    if (![dateTimer isValid]) {
        dateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateDateLabel) userInfo:nil repeats:YES];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:self.postDate withFormatter:[kAppDelegate dateFormatter]];
    
    [[self dateLabel] setText:[[kAppDelegate dateTransformer] transformedValue:tempDate]];
}

-(void)updateDateLabel
{
    NSDate *tempDate = [NSDate dateWithISO8601String:self.postDate withFormatter:[kAppDelegate dateFormatter]];
    
    [[self dateLabel] setText:[[kAppDelegate dateTransformer] transformedValue:tempDate]];
}

@end
