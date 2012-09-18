//
//  SelfWithImageCellView.h
//  Jukaela
//
//  Created by Josh on 9/18/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelfCellView.h"

@interface SelfWithImageCellView : SelfCellView

@property (strong, nonatomic) UIImageView *externalImage;
@property (strong, nonatomic) UIActivityIndicatorView *externalActivityIndicator;

@end
