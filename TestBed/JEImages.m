//
//  JEImages.m
//  HomeInventory
//
//  Created by Josh Barrow on 4/13/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JEImages.h"

@implementation JEImages


+(UIImage *)normalize:(UIImage *)theImage
{    
    CGColorSpaceRef genericColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef thumbBitmapCtxt = CGBitmapContextCreate(NULL, 
                                                         theImage.size.width, 
                                                         theImage.size.height, 
                                                         8, (4 * theImage.size.width), 
                                                         genericColorSpace, 
                                                         2);
    
    CGColorSpaceRelease(genericColorSpace);
    CGContextSetInterpolationQuality(thumbBitmapCtxt, kCGInterpolationDefault);
    CGRect destRect = CGRectMake(0, 0, theImage.size.width, theImage.size.height);
    CGContextDrawImage(thumbBitmapCtxt, destRect, theImage.CGImage);
    CGImageRef tmpThumbImage = CGBitmapContextCreateImage(thumbBitmapCtxt);
    CGContextRelease(thumbBitmapCtxt);    
    UIImage *result = [UIImage imageWithCGImage:tmpThumbImage];
    CGImageRelease(tmpThumbImage);
    
    return result;    
}

+(UIImage *)getImageFromColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img stretchableImageWithLeftCapWidth:0 topCapHeight:0];
}
@end
