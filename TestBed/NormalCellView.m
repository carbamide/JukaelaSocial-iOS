//
//  NormalCellView.m
//  Jukaela Social
//
//  Created by Josh Barrow on 09/09/2012.
//  Copyright 2012 Josh Barrow. All rights reserved.
//

@import ObjectiveC.runtime;

#import "Constants.h"
#import "NormalCellView.h"
#import "User.h"
#import "GravatarHelper.h"

NSString * const kJKPrepareForReuseNotification = @"TableViewCell_PrepareForReuse2";

@interface NormalCellView ()
@property (weak, nonatomic) UITableView *theTableView;
@property (strong, nonatomic) NSIndexPath *indexPath;

@end

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

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	
	if (self) {
        [self setIndexPath:indexPath];
        [self setTheTableView:tableView];
        
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
    if (![self tapGesture]) {
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        
        [tapGesture setNumberOfTapsRequired:1];
        
        [self addGestureRecognizer:tapGesture];
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
            NSIndexPath *indexPath = [[self theTableView] indexPathForCell:self];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kTapNotification object:nil userInfo:@{kIndexPath : indexPath}];
        }
    }
    else {
        NSIndexPath *indexPath = [[self theTableView] indexPathForCell:self];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kTapNotification object:nil userInfo:@{kIndexPath : indexPath}];
    }
}

-(void)sendToUser:(UIGestureRecognizer *)gesture
{
    NSIndexPath *indexPath = [[self theTableView] indexPathForCell:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSendToUserNotification object:nil userInfo:@{kIndexPath : indexPath}];
}

-(void)repostSendToUser:(UIGestureRecognizer *)gesture
{
    NSIndexPath *indexPath = [[self theTableView] indexPathForCell:self];
    
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

-(void)setDate:(NSDate *)date
{
    postDate = date;
    
    if (![dateTimer isValid]) {
        dateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateDateLabel) userInfo:nil repeats:YES];
    }
    
    [[self dateLabel] setText:[[kAppDelegate dateTransformer] transformedValue:postDate]];
}

-(void)updateDateLabel
{
    [[self dateLabel] setText:[[kAppDelegate dateTransformer] transformedValue:postDate]];
}

-(void)configureCellForFeedItem:(FeedItem *)feedItem nameDict:(NSDictionary *)nameDict
{
    if ([feedItem content]) {
        [[self contentText] setText:[feedItem content]];
    }
    else {
        [[self contentText] setText:@"Loading..."];
    }
    
    if ([[feedItem user] name]) {
        [[self nameLabel] setText:[[feedItem user] name]];
    }
    else {
        if ([[feedItem user] userId]) {
            [[self nameLabel] setText:[NSString stringWithFormat:@"%@", nameDict[[[feedItem user] userId]]]];
        }
        else {
            [[self nameLabel] setText:@"Loading..."];
        }
    }
    
    if ([[feedItem user] username]) {
        [[self usernameLabel] setText:[NSString stringWithFormat:@"@%@", [[feedItem user] username]]];
    }
    
    if ([feedItem repostUserId]) {
        [[self repostedNameLabel] setUserInteractionEnabled:YES];
        
        CGSize contentSize;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([feedItem imageUrl]) {
            contentSize = [[feedItem content] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                         constrainedToSize:CGSizeMake(185 - (7.5 * 2), 20000)
                                             lineBreakMode:NSLineBreakByWordWrapping];
        }
        else {
            contentSize = [[feedItem content] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                         constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                             lineBreakMode:NSLineBreakByWordWrapping];
        }
        
        CGSize nameSize = [[[feedItem user] name] sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
                                             constrainedToSize:CGSizeMake(215 - (7.5 * 2), 20000)
                                                 lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
        
        CGFloat height = jMAX(contentSize.height + nameSize.height + 10, 85);
        
        [[self repostedNameLabel] setFrame:CGRectMake(7, height - 5, 228, 20)];
        
        [[self repostedNameLabel] setText:[NSString stringWithFormat:@"Reposted by %@", [feedItem repostName]]];
    }
    else {
        [[self repostedNameLabel] setUserInteractionEnabled:NO];
    }
    
    [self setDate:[feedItem createdAt]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(self, kIndexPathAssociationKey, [self indexPath], OBJC_ASSOCIATION_RETAIN);
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@.png", [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]]] error:nil];
    
    if (image) {
        [[self imageView] setImage:image];
        [self setNeedsDisplay];
        
        if (attributes) {
            if ([NSDate daysBetweenDate:[NSDate date] andDate:attributes[NSFileCreationDate] options:0] > 1) {
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[[feedItem user] email] withSize:40]]];
                    
#if (TARGET_IPHONE_SIMULATOR)
//                    image = [UIImage normalize:image];
#endif
                    UIImage *resizedImage = [image thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSIndexPath *selfIndexPath = (NSIndexPath *)objc_getAssociatedObject(self, kIndexPathAssociationKey);
                        
                        if ([[self indexPath] isEqual:selfIndexPath]) {
                            [[self imageView] setImage:resizedImage];
                            [self setNeedsDisplay];
                        }
                        
                        [UIImage saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]];
                    });
                });
            }
        }
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[[feedItem user] email] withSize:40]]];
            
#if (TARGET_IPHONE_SIMULATOR)
//            image = [JEImages normalize:image];
#endif
            UIImage *resizedImage = [image thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *selfIndexPath = (NSIndexPath *)objc_getAssociatedObject(self, kIndexPathAssociationKey);
                
                if ([[self indexPath] isEqual:selfIndexPath]) {
                    [[self imageView] setImage:resizedImage];
                    [self setNeedsDisplay];
                }
                
                [UIImage saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [[feedItem user] userId]]];
            });
        });
    }

}
@end
