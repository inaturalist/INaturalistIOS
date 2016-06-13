//
//  TKCoverflowCoverView+INaturalist.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 4/2/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "TKCoverflowCoverView+INaturalist.h"

@implementation TKCoverflowCoverView (INaturalist)

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletionBlock)completion
{
    [self.imageView sd_setImageWithURL:url
                      placeholderImage:placeholder
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 completion(image, error, cacheType, imageURL);
                             }];
}

@end
