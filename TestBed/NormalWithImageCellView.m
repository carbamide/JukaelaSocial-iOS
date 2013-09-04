//
//  NormalWithImageCellView.m
//  Jukaela
//
//  Created by Josh on 9/18/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "NormalWithImageCellView.h"
#import "FeedViewController.h"
#import "User.h"

@interface NormalWithImageCellView ()
@property (weak, nonatomic) UITableView *theTableView;
@property (weak, nonatomic) NSCache *externalImageCache;
@property (weak, nonatomic) NSIndexPath *indexPath;
@end

@implementation NormalWithImageCellView

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
      withTableView:(UITableView *)tableView
     withImageCache:(NSCache *)cache
      withIndexPath:(NSIndexPath *)indexPath
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier withTableView:tableView withIndexPath:indexPath];
    
    if (self) {
        [self setTheTableView:tableView];
        [self setExternalImageCache:cache];
        [self setIndexPath:indexPath];
        
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
    NSIndexPath *indexPath = [[self theTableView] indexPathForCell:self];
    
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

-(void)setImageUrl:(NSURL *)imageUrl
{
    _imageUrl = imageUrl;
    
    if (imageUrl) {
        NSMutableString *tempString = [NSMutableString stringWithString:[imageUrl absoluteString]];
        
        NSString *tempExtensionString = [NSString stringWithFormat:@".%@", [tempString pathExtension]];
        
        [tempString stringByReplacingOccurrencesOfString:tempExtensionString withString:@""];
        [tempString appendFormat:@"s"];
        [tempString appendString:tempExtensionString];
        
        if (![[self externalImage] image]) {
            if ([[self externalImageCache] objectForKey:[self indexPath]]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                    UIImage *tempImage = [[[self externalImageCache] objectForKey:[self indexPath]] thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self externalImage] setImage:tempImage];
                    });
                });
            }
            else if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSString documentsPath] stringByAppendingPathComponent:[tempString lastPathComponent]]]) {
                UIImage *externalImageFromDisk = [UIImage imageWithData:[NSData dataWithContentsOfFile:[[NSString documentsPath] stringByAppendingPathComponent:[tempString lastPathComponent]]]];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                    UIImage *tempImage = [externalImageFromDisk thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self externalImage] setImage:tempImage];
                    });
                });
                
                if (externalImageFromDisk) {
                    [[self externalImageCache] setObject:externalImageFromDisk forKey:[self indexPath]];
                }
            }
            else {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
                
                objc_setAssociatedObject(self, kIndexPathAssociationKey, [self indexPath], OBJC_ASSOCIATION_RETAIN);
                
                dispatch_async(queue, ^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
                    
                    if (image) {
                        [[self externalImageCache] setObject:image forKey:[self indexPath]];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self externalImage] setImage:[image thumbnailImage:75 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh]];
                        
                        [UIImage saveImage:image withFileName:[tempString lastPathComponent]];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            NSString *path = [[NSString documentsPath] stringByAppendingPathComponent:[NSString stringWithString:[tempString lastPathComponent]]];
                            
                            NSData *data = nil;
                            
                            if ([[tempString pathExtension] isEqualToString:@".png"]) {
                                data = UIImagePNGRepresentation(image);
                            }
                            else {
                                data = UIImageJPEGRepresentation(image, 1.0);
                            }
                            
                            [data writeToFile:path atomically:YES];
                        });
                    });
                });
            }
        }
    }
}

-(void)configureCellForFeedItem:(FeedItem *)feedItem nameDict:(NSDictionary *)nameDict
{
    [super configureCellForFeedItem:feedItem nameDict:nameDict];
    
    if ([feedItem imageUrl]) {
        [self setImageUrl:[feedItem imageUrl]];
    }
}
@end
