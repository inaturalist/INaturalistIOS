//
//  UIImage+INaturalist.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

@import UIColor_HTMLColors;

#import "UIImage+INaturalist.h"
#import "INaturalist-Swift.h"

@implementation UIImage (INaturalist)

+ (instancetype)inat_defaultGuideImage {
    return [UIImage iconImageWithSystemName:@"book" size:IconImageSizeMedium];
}

+ (instancetype)inat_defaultProjectImage {
    return [UIImage iconImageWithSystemName:@"briefcase" size:IconImageSizeMedium];
}

+ (instancetype)inat_defaultUserImage {
    return [UIImage iconImageWithSystemName:@"person" size:IconImageSizeMedium];
}


- (NSData *)inat_JPEGDataRepresentationWithMetadata:(NSDictionary *)metadata quality:(CGFloat)quality {
    NSMutableData *destMutableData = [NSMutableData data];
    
    NSData *jpegData = UIImageJPEGRepresentation(self, quality);
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)jpegData,
                                                          NULL);
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)destMutableData,
                                                                         (CFStringRef) @"public.jpeg",
                                                                         1,
                                                                         NULL);
    CGImageDestinationAddImageFromSource(destination, source,0, (CFDictionaryRef) metadata);
    CGImageDestinationFinalize(destination);
    
    CFRelease(destination);
    CFRelease(source);
    
    return [NSData dataWithData:destMutableData];
}


@end
