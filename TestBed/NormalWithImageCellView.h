//
//  NormalWithImageCellView.h
//  Jukaela
//
//  Created by Josh on 9/18/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NormalCellView.h"

@interface NormalWithImageCellView : NormalCellView

@property (strong, nonatomic) UIImageView *externalImage;
@property (strong, nonatomic) UIActivityIndicatorView *externalActivityIndicator;

@end
