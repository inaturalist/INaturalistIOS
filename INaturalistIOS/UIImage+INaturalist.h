//
//  UIImage+INaturalist.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (INaturalist)

+ (instancetype)inat_defaultProjectImage;
+ (instancetype)inat_defaultGuideImage;
+ (instancetype)inat_defaultUserImage;
- (instancetype)inat_imageByAddingBorderWidth:(CGFloat)borderWidth radius:(CGFloat)radius color:(UIColor *)color;

- (NSData *)inat_JPEGDataRepresentationWithMetadata:(NSDictionary *)metadata;
@end
