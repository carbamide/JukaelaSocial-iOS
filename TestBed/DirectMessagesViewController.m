//
//  DirectMessagesViewController.m
//  Jukaela
//
//  Created by Josh on 12/9/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "DirectMessagesViewController.h"
#import "NormalCellView.h"
#import "CellBackground.h"
#import <objc/message.h>
#import "GravatarHelper.h"
#import "JEImages.h"
#import "SORelativeDateTransformer.h"

@interface DirectMessagesViewController ()
@property (strong, nonatomic) NSArray *messagesArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) YIFullScreenScroll *fullScreenDelegate;

@end

@implementation DirectMessagesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [_fullScreenDelegate layoutTabBarController];

    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doubleTap:) name:@"double_tap" object:nil];

    _fullScreenDelegate = [[YIFullScreenScroll alloc] initWithViewController:self];

    JRefreshControl *refreshControl = [[JRefreshControl alloc] init];
    
    [refreshControl setTintColor:[UIColor blackColor]];
    
    [refreshControl addTarget:self action:@selector(getMessages) forControlEvents:UIControlEventValueChanged];
    
    [self setRefreshControl:refreshControl];
    
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(showComposer:)]];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [[self view] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
	[self getMessages];
}

-(void)showComposer:(id)sender
{
    [self performSegueWithIdentifier:@"Compose" sender:nil];;
}

-(void)getMessages
{
    if ([self messagesArray]) {
        [self setMessagesArray:nil];
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/direct_messages.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setMessagesArray:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[self tableView] reloadData];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading your direct messages..  Please logout and log back in."];
        }
        
        [[self refreshControl] endRefreshing];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentText = [self messagesArray][[indexPath row]][@"content"];
    
    CGSize constraint = CGSizeMake(300, 20000);
    
    CGSize contentSize = [contentText sizeWithFont:[UIFont fontWithName:@"Helvetica-Light" size:17] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    
    return contentSize.height + 50 + 10;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self messagesArray] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DirectMessagesCell";
    
    NormalCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[NormalCellView alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell setBackgroundView:[[CellBackground alloc] init]];
    }
    
    [[cell contentText] setFontName:@"Helvetica-Light"];
    [[cell contentText] setFontSize:17];
    
    if ([self messagesArray][[indexPath row]][@"content"] && [self messagesArray][[indexPath row]][@"content"] != [NSNull null]) {
        [[cell contentText] setText:[self messagesArray][[indexPath row]][@"content"]];
    }
    [[cell nameLabel] setText:[self messagesArray][[indexPath row]][@"from_name"]];
    
    if ([self messagesArray][[indexPath row]][@"from_username"] && [self messagesArray][[indexPath row]][@"from_username"] != [NSNull null]) {
        [[cell usernameLabel] setText:[self messagesArray][[indexPath row]][@"from_username"]];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self messagesArray][[indexPath row]][@"created_at"] withFormatter:[self dateFormatter]];
    
    [[cell dateLabel] setText:[[self dateTransformer] transformedValue:tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self messagesArray][[indexPath row]][@"from_user_id"]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    objc_setAssociatedObject(cell, kIndexPathAssociationKey, indexPath, OBJC_ASSOCIATION_RETAIN);
    
    if (image) {
        [[cell imageView] setImage:image];
        [cell setNeedsDisplay];
    }
    else {
        dispatch_async(queue, ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self messagesArray][[indexPath row]][@"from_email"] withSize:65]]];
            
#if (TARGET_IPHONE_SIMULATOR)
            image = [JEImages normalize:image];
#endif
            UIImage *resizedImage = [image thumbnailImage:65 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
                
                if ([indexPath isEqual:cellIndexPath]) {
                    [[cell imageView] setImage:resizedImage];
                    [cell setNeedsDisplay];
                }
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@", [self messagesArray][[indexPath row]][@"user_id"]]];
            });
        });
        
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_fullScreenDelegate scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_fullScreenDelegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [_fullScreenDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    return [_fullScreenDelegate scrollViewShouldScrollToTop:scrollView];;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [_fullScreenDelegate scrollViewDidScrollToTop:scrollView];
}

-(void)doubleTap:(NSNotification *)aNotification
{
    [_fullScreenDelegate showUIBarsWithScrollView:[self tableView] animated:YES];
}

@end
