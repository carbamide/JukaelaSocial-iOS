//
//  WBBaseNoticeView.m
//  NoticeView
//
//  Created by Tito Ciuro on 5/25/12.
//  Copyright (c) 2012 Tito Ciuro. All rights reserved.
//

#import "WBBaseNoticeView.h"

@implementation WBBaseNoticeView

- (id)initWithView:(UIView *)theView title:(NSString *)theTitle
{
    [WBBaseNoticeView raiseIfObjectIsNil:theView named:@"view"];
    
    if (self = [super init]) {
        self.view = theView;
        self.title = theTitle;
    }
    
    return self;
}

- (void)show
{
    // Subclasses need to override this method...
    [self doesNotRecognizeSelector:_cmd];
}

+ (void)raiseIfObjectIsNil:(id)object named:(NSString *)name
{
    if (nil == object) {
        // If the name has not been supplied, name it generically
        
        // Log the stack trace
        NSLog(@"%@", [NSThread callStackSymbols]);
        
        [NSException exceptionWithName:@"Oh crap" reason:@"Something went wrong" userInfo:nil];
    }
}

#pragma mark - Properties

@synthesize noticeType;
@synthesize view;
@synthesize title;
@synthesize duration;
@synthesize delay;
@synthesize alpha;
@synthesize originY;

@end
