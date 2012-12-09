//
//  DirectMessagesViewController.m
//  Jukaela
//
//  Created by Josh on 12/9/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "DirectMessagesViewController.h"
#import "UsersCell.h"
#import "CellBackground.h"
#import <objc/message.h>
#import "GravatarHelper.h"
#import "JEImages.h"

@interface DirectMessagesViewController ()
@property (strong, nonatomic) NSArray *messagesArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation DirectMessagesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"underPageBackground.png"]]];
    
	[self getMessages];
}

-(void)getMessages
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/direct_messages.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setMessagesArray:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            NSLog(@"%@", [self messagesArray]);
            
            [[self tableView] reloadData];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        else {
            [Helpers errorAndLogout:self withMessage:@"There was an error loading your direct messages..  Please logout and log back in."];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self messagesArray] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DirectMessagesCell";
    
    UsersCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UsersCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell setBackgroundView:[[CellBackground alloc] init]];
    }
    
    [[cell contentText] setFontName:@"Helvetica-Light"];
    [[cell contentText] setFontSize:18];
    
    [[cell contentText] setText:[self messagesArray][[indexPath row]][@"from_name"]];
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self messagesArray][[indexPath row]][@"created_at"] withFormatter:[self dateFormatter]];

    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", tempDate]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@-large.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self messagesArray][[indexPath row]][@"from_user_id"]]]]];
    
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
                    
                    [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@-large", [self messagesArray][[indexPath row]][@"user_id"]]];
                });
            });

    }
    
    return cell;
}
@end
