//
//  TKCoverflowCoverView+INaturalist.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 4/2/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//
// Add some methods to load remote images

#import <TapkuLibrary/TapkuLibrary.h>
#import "UIImageView+WebCache.h"

@interface TKCoverflowCoverView (INaturalist)
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setRemotelyLoadedImage:(UIImage *)img;
- (void)setIsReflected:(bool)isReflected;
@end
