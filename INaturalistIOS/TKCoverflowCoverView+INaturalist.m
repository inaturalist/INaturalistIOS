//
//  TKCoverflowCoverView+INaturalist.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 4/2/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "TKCoverflowCoverView+INaturalist.h"

@implementation TKCoverflowCoverView (INaturalist)
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock
{
    TKCoverflowCoverView *boundCover = self;
    [imageView setImageWithURL:url
                    placeholderImage:placeholder
                           completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                               if (!error) {
                                   [boundCover setRemotelyLoadedImage:image];
                               }
                               completedBlock(image, error, cacheType);
                           }];
}

- (void)setRemotelyLoadedImage:(UIImage *)img
{
    UIImage *image = img;
	
	float w = image.size.width;
	float h = image.size.height;
	float factor = self.bounds.size.width / (h>w?h:w);
	h = factor * h;
	w = factor * w;
    float x = (imageView.frame.size.width - w) / 2; // this is the key difference, not sure why they use the overall frame in the original
	float y = baseline - h > 0 ? baseline - h : 0;
	imageView.frame = CGRectMake(x, y, w, h);
	imageView.image = image;
	gradientLayer.frame = CGRectMake(x, y + h, w, h);
	reflected.frame = CGRectMake(x, y + h, w, h);
	reflected.image = image;
}

- (void)setIsReflected:(bool)isReflected
{
    [reflected setHidden:!isReflected];
}
@end
