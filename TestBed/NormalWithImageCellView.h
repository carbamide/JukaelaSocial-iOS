//
//  NormalWithImageCellView.h
//  Jukaela
//
//  Created by Josh on 9/18/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@import UIKit;
#import "NormalCellView.h"

@interface NormalWithImageCellView : NormalCellView

@property (strong, nonatomic) UIImageView *externalImage;
@property (strong, nonatomic, setter = setImageUrl:) NSURL *imageUrl;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withTableView:(UITableView *)tableView withImageCache:(NSCache *)cache withIndexPath:(NSIndexPath *)indexPath;

@end
