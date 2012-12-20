//
//  DirectMessageComposerViewController.m
//  Jukaela
//
//  Created by Josh on 12/9/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "DirectMessageComposerViewController.h"
#import "AppDelegate.h"
#import "GravatarHelper.h"
#import "CellBackground.h"

@interface DirectMessageComposerViewController ()
@property (strong, nonatomic) NSMutableArray *usernameArray;
@property (strong, nonatomic) NSMutableArray *autocompleteUsernames;
@end

@implementation DirectMessageComposerViewController

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
    
    _usernameTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.textField.frame.origin.x + 10, 50, self.textField.frame.size.width, 130) style:UITableViewStylePlain];
    
    [_usernameTableView setDelegate:self];
    [_usernameTableView setDataSource:self];
    [_usernameTableView setScrollEnabled:YES];
    [_usernameTableView setHidden:YES];
    
    [[_usernameTableView layer] setCornerRadius:8];
    [[_usernameTableView layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[_usernameTableView layer] setBorderWidth:1];
    
    [[self view] addSubview:_usernameTableView];
    
    [self getUsers];
    
    [self setAutocompleteUsernames:[[NSMutableArray alloc] init]];
    
    UIWindow *tempWindow = [kAppDelegate window];
    
    if (tempWindow.frame.size.height > 500) {
        [[self countDownLabel] setFrame:CGRectMake(_countDownLabel.frame.origin.x, _countDownLabel.frame.origin.y + 100, _countDownLabel.frame.size.width, _countDownLabel.frame.size.height)];
        [[self textView] setFrame:CGRectMake(_textView.frame.origin.x, _textView.frame.origin.y, _textView.frame.size.width, _textView.frame.size.height + 100)];
    }
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@-large.png", [[Helpers documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [kAppDelegate userID]]]]];
    
    if (image) {
        [[self imageView] setImage:image];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            UIImage *tempImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[kAppDelegate userEmail] withSize:65]]];
            
            UIImage *resizedImage = [tempImage thumbnailImage:65 transparentBorder:5 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self imageView] setImage:resizedImage];
                
                [Helpers saveImage:resizedImage withFileName:[NSString stringWithFormat:@"%@-large", [kAppDelegate userID]]];
            });
        });
    }
    
    CGRect backgroundRect = self.backgroundView.frame;
    CGRect userImageRect = self.imageView.frame;
    
    [[self imageView] setClipsToBounds:NO];
    
    [[[self imageView] layer] setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [[[self imageView] layer] setShadowRadius:8];
    [[[self imageView] layer] setShadowOpacity:0.8];
    [[[self imageView] layer] setShadowOffset:CGSizeMake(-12, -10)];
    [[[self imageView] layer] setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:userImageRect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8, 8)] CGPath]];
    
    [[[self backgroundView] layer] setCornerRadius:8];
    
    [[[self backgroundView] layer] setShadowColor:[[UIColor blackColor] CGColor]];
    [[[self backgroundView] layer] setShadowRadius:8];
    [[[self backgroundView] layer] setShadowOpacity:1.0];
    [[[self backgroundView] layer] setShadowOffset:CGSizeMake(-8, -15)];
    [[[self backgroundView] layer] setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:backgroundRect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8, 8)] CGPath]];
    
    [[[self textView] layer] setCornerRadius:8];
    [[[self textView] layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[[self textView] layer] setBorderWidth:1];
    
    [[[self textField] layer] setCornerRadius:8];
    [[[self textField] layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[[self textField] layer] setBorderWidth:1];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextViewTextDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [self updateCount];
    }];
    
    [[self textField] becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(IBAction)post:(id)sender
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/direct_messages.json", kSocialURL]];
    
    NSString *requestString = [RequestFactory directMessageRequestWithContent:[[self textView] text] userID:[kAppDelegate userID] username:[[self textField] text]];
        
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (!data) {
            BlockAlertView *alert = [[BlockAlertView alloc] initWithTitle:@"Error" message:@"There has been an error sending your message."];
            
            [alert setCancelButtonWithTitle:@"OK" block:nil];
            
            [alert show];
        }
        else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)updateCount
{
    NSUInteger maxCount = 256;
    
    NSUInteger textCount = [self.textView.text length];
    
    [_countDownLabel setText:[NSString stringWithFormat:@"%d", maxCount-textCount]];
    
    if (textCount > maxCount) {
        [_countDownLabel setTextColor:[UIColor redColor]];
    }
    else {
        [_countDownLabel setTextColor:[UIColor darkGrayColor]];
    }
    
    [[self postButton] setEnabled:![[_countDownLabel text] isEqualToString:@"256"]];
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    [_autocompleteUsernames removeAllObjects];
    
    for (NSString *curString in [self usernameArray]) {
        NSRange substringRange = [curString rangeOfString:substring options:NSCaseInsensitiveSearch];
        if (substringRange.location == 0) {
            [_autocompleteUsernames addObject:curString];
        }
    }
    
    [[self usernameTableView] reloadData];
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [[self usernameTableView] setHidden:NO];
    
    NSString *substring = [NSString stringWithString:[textField text]];
    substring = [substring stringByReplacingCharactersInRange:range withString:string];
    
    [self searchAutocompleteEntriesWithSubstring:substring];
    
    return YES;
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{
    if ([[self autocompleteUsernames] count] == 0) {
        [tableView setHidden:YES];
    }
    
    return [[self autocompleteUsernames] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    static NSString *AutoCompleteRowIdentifier = @"AutoCompleteRowIdentifier";
    
    cell = [tableView dequeueReusableCellWithIdentifier:AutoCompleteRowIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AutoCompleteRowIdentifier];
        
        [cell setBackgroundView:[[CellBackground alloc] init]];
        
        
    }
    
    [[cell textLabel] setFont:[UIFont fontWithName:kHelveticaLight size:14]];
    
    [[cell textLabel] setText:[[self autocompleteUsernames] objectAtIndex:[indexPath row]]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    [[self textField] setText:[[selectedCell textLabel] text]];
    
    [tableView setHidden:YES];
}

-(void)getUsers
{
    if (![self usernameArray]) {
        [self setUsernameArray:[[NSMutableArray alloc] init]];
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users.json", kSocialURL]];
    
    NSMutableURLRequest *request = [Helpers getRequestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            NSArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
            
            for (id userDict in tempArray) {
                if (userDict[kUsername] && userDict[kUsername] != [NSNull null]) {
                    [[self usernameArray] addObject:userDict[kUsername]];
                }
            }
        }
        else {
            NSLog(@"Error retrieving users");
        }
    }];
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [_usernameTableView setHidden:YES];
    
    return YES;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    if (![_usernameTableView isHidden]) {
        id view = [touch view];
        
        if (![view isEqual:_usernameTableView]) {
            [_usernameTableView setHidden:YES];
        }
    }
}

@end
