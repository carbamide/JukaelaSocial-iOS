// Extends the UIImage class to support resizing/cropping
@interface UIImage (Resize)
-(UIImage *)croppedImage:(CGRect)bounds;
-(UIImage *)thumbnailImage:(NSInteger)thumbnailSize
          transparentBorder:(NSUInteger)borderSize
               cornerRadius:(NSUInteger)cornerRadius
       interpolationQuality:(CGInterpolationQuality)quality;
-(UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;
-(UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;
-(UIImage *)scaleAndRotateImage:(UIImage *)image withMaxSize:(int)maxSize;
-(CGAffineTransform)transformForOrientation:(CGSize)newSize;
-(UIImage *)resizedImage:(CGSize)newSize
               transform:(CGAffineTransform)transform
          drawTransposed:(BOOL)transpose
    interpolationQuality:(CGInterpolationQuality)quality;

@end
