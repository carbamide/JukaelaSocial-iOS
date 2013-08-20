//
//  JukaelaTextView.m
//  Jukaela
//
//  Created by Josh on 8/20/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "JukaelaTextView.h"

@interface JukaelaTextView ()

@property (nonatomic, retain) UILabel *placeHolderLabel;

@end

static const int PLACEHOLDER_TAG = 999;

@implementation JukaelaTextView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (![self placeholder]) {
        [self setPlaceholder:@""];
    }
    
    if (![self placeholderColor]) {
        [self setPlaceholderColor:[UIColor lightGrayColor]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setPlaceholder:@""];
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)textChanged:(NSNotification *)notification
{
    if ([[self placeholder] length] == 0) {
        return;
    }
    
    if ([[self text] length] == 0) {
        [[self viewWithTag:PLACEHOLDER_TAG] setAlpha:1];
    }
    else {
        [[self viewWithTag:PLACEHOLDER_TAG] setAlpha:0];
    }
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    
    [self textChanged:nil];
}

- (void)drawRect:(CGRect)rect
{
    if( [[self placeholder] length] > 0 ) {
        if (_placeHolderLabel == nil ) {
            [self setPlaceHolderLabel:[[UILabel alloc] initWithFrame:CGRectMake(8,8,self.bounds.size.width - 16,0)]];
            
            [_placeHolderLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [_placeHolderLabel setNumberOfLines:0];
            [_placeHolderLabel setFont:[self font]];
            [_placeHolderLabel setBackgroundColor:[UIColor clearColor]];
            [_placeHolderLabel setTextColor:[self placeholderColor]];
            [_placeHolderLabel setAlpha:0];
            [_placeHolderLabel setTag:PLACEHOLDER_TAG];
            
            [self addSubview:_placeHolderLabel];
        }
        
        _placeHolderLabel.text = self.placeholder;
        [_placeHolderLabel sizeToFit];
        
        [self sendSubviewToBack:_placeHolderLabel];
    }
    
    if ([[self text] length] == 0 && [[self placeholder] length] > 0) {
        [[self viewWithTag:PLACEHOLDER_TAG] setAlpha:1];
    }
    
    [super drawRect:rect];
}

@end
