//
//  ShareObject.m
//  Jukaela
//
//  Created by Josh on 9/11/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "NormalCellView.h"
#import "ShareManager.h"

@implementation ShareManager

+(void)shareToTwitter:(NSString *)stringToSend withViewController:(FeedViewController *)feedViewController
{
    [feedViewController initializeActivityIndicator];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:0 completion:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            
            if ([accountsArray count] > 0) {
                ACAccount *twitterAccount = accountsArray[0];
                
                SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] parameters:@{@"status" : stringToSend}];
                
                [postRequest setAccount:twitterAccount];
                
                [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    if (responseData) {
                        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                        
                        NSLog(@"The Twitter response was \n%@", jsonData);
                        
                        if (!jsonData[@"error"]) {
                            NSLog(@"Successfully posted to Twitter");
                        }
                        else {
                            NSLog(@"%@", jsonData[@"error"]);
                            NSLog(@"Not posted to Twitter");
                        }
                    }
                    else {
                        UIAlertView *twitterPostingError = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"There has been an error sharing to Twitter." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                                                                        
                        [twitterPostingError show];
                    }
                    [[feedViewController activityIndicator] stopAnimating];
                }];
            }
        }
    }];
}

+(void)shareToFacebook:(NSString *)stringToSend withViewController:(FeedViewController *)feedViewController
{
    [feedViewController initializeActivityIndicator];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    if (NSStringFromClass([SLRequest class])) {
        if (accountStore == nil) {
            accountStore = [[ACAccountStore alloc] init];
        }
        
        ACAccountType *accountTypeFacebook = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        
        NSDictionary *options = @{ACFacebookAppIdKey:@"493749340639998", ACFacebookAudienceKey: ACFacebookAudienceEveryone, ACFacebookPermissionsKey: @[@"publish_stream", @"publish_actions", @"read_friendlists"]};
        
        [accountStore requestAccessToAccountsWithType:accountTypeFacebook options:options completion:^(BOOL granted, NSError *error) {
            if(granted) {
                NSArray *accounts = [accountStore accountsWithAccountType:accountTypeFacebook];
                
                ACAccount *facebookAccount = [accounts lastObject];
                
                NSAssert([[facebookAccount credential] oauthToken], @"The OAuth token is invalid", nil);
                
                NSDictionary *parameters = @{@"access_token":[[facebookAccount credential] oauthToken], @"message":stringToSend};
                
                NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
                
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
                
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *errorDOIS) {
                    if (responseData) {
                        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                        
                        NSLog(@"The Facebook response was \n%@", jsonData);
                        
                        if (!jsonData[@"error"]) {
                            NSLog(@"Successfully posted to Facebook");
                        }
                        else {
                            NSLog(@"Not posted to Facebook");
                        }
                    }
                    else {

                    }
                    [[feedViewController activityIndicator] stopAnimating];
                }];
            }
            else {
                NSLog(@"Facebook access not granted.");
                NSLog(@"%@", [error localizedDescription]);
            }
        }];
    }
}

+(void)repost:(NSIndexPath *)indexPathOfCell fromArray:(NSArray *)theArray withViewController:(FeedViewController *)viewController
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@/repost.json", kSocialURL, theArray[[indexPathOfCell row]][kID]]];
    
    NSData *tempData = [[theArray[[indexPathOfCell row]][kContent] stringWithSlashEscapes] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *stringToSendAsContent = [[NSString alloc] initWithData:tempData encoding:NSASCIIStringEncoding];
    
    NSString *requestString = [RequestFactory postRequestWithContent:stringToSendAsContent userID:[kAppDelegate userID] imageURL:nil withReplyTo:nil];
        
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [Helpers postRequestWithURL:url withData:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshYourTablesNotification object:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kJukaelaSuccessfulNotification object:nil];
            
            [[ActivityManager sharedManager] decrementActivityCount];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kStopAnimatingActivityIndicator object:nil];
        }
        else {
            NSLog(@"Error");
        }
    }];
}
@end
