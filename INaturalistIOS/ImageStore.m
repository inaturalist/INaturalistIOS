//
//  ImageStore.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
// 
//  Largely based on the ImageStore example in iOS Programming: The Big Nerd Range Guide, 
//  Second Edition by Joe Conway and Aaron Hillegass.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <SDWebImage/SDImageCache.h>

#import "ImageStore.h"
#import "Analytics.h"

#define INATURALIST_ORG_MAX_PHOTO_EDGE      2048

@interface ImageStore () {
    NSOperationQueue *resizeQueue;
    SDImageCache *_nonexpiringImageCache;
}
@property (readonly) SDImageCache *nonexpiringImageCache;
@end

@implementation ImageStore
@synthesize dictionary;

// singleton
+ (ImageStore *)sharedImageStore {
    static ImageStore *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[ImageStore alloc] init];
    });
    return _sharedInstance;
}

- (SDImageCache *)nonexpiringImageCache {
    if (!_nonexpiringImageCache) {
        _nonexpiringImageCache = [[SDImageCache alloc] initWithNamespace:@"inat.nonexpiring"];
        _nonexpiringImageCache.maxCacheAge = DBL_MAX;
        _nonexpiringImageCache.maxCacheSize = 0;
    }
    
    return _nonexpiringImageCache;
}


- (instancetype)init {
    if (self = [super init]) {
        [self setDictionary:[[NSMutableDictionary alloc] init]];
        
        resizeQueue = [[NSOperationQueue alloc] init];
        resizeQueue.maxConcurrentOperationCount = 1;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(clearCache:)
                                                   name:UIApplicationDidReceiveMemoryWarningNotification
                                                 object:nil];
    }
    return self;
}

- (UIImage *)find:(NSString *)key
{
    return [self find:key forSize:ImageStoreLargeSize];
}

- (UIImage *)find:(NSString *)key forSize:(int)size {
    NSString *imgKey = [self keyForKey:key forSize:size];
    UIImage *img = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imgKey];
    
    if (!img) {
        // attempt to find it at the old path
        NSString *oldPath = [self oldPathForKey:key forSize:size];
        img = [UIImage imageWithContentsOfFile:oldPath];

        if (img) {
            // move to new path (ie save in sdimagecache]
            [[SDImageCache sharedImageCache] storeImage:img forKey:imgKey];
            
            // reload it from the new location
            img = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imgKey];
            
            // delete the old file
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
        }
    }
    
    return img;
}

- (BOOL)storeAsset:(ALAsset *)asset forKey:(NSString *)key error:(NSError *__autoreleasing *)storeError {
    [[Analytics sharedClient] debugLog:@"ASSET STORE: begin"];
    
    @autoreleasepool {
        // large = fullsize image but truncated to 2048x2048 pixels max (aspect ratio scaled)
        UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
        UIImage *resized = [self imageResized:image longEdge:INATURALIST_ORG_MAX_PHOTO_EDGE];
        NSString *largeKey = [self keyForKey:key forSize:ImageStoreLargeSize];
        [[self nonexpiringImageCache] storeImage:resized forKey:largeKey];
    }
    
    @autoreleasepool {
        // small = full screen asset
        UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
        NSString *smallKey = [self keyForKey:key forSize:ImageStoreSmallSize];
        [[SDImageCache sharedImageCache] storeImage:image forKey:smallKey];
    }
    
    @autoreleasepool {
        // square = asset thumbnail
        UIImage *image = [UIImage imageWithCGImage:asset.thumbnail];
        NSString *squareKey = [self keyForKey:key forSize:ImageStoreSquareSize];
        [[SDImageCache sharedImageCache] storeImage:image forKey:squareKey];
    }
    
    [[Analytics sharedClient] debugLog:@"ASSET STORE: done"];
    return YES;
}

- (UIImage *)imageResized:(UIImage *)image longEdge:(CGFloat)longEdge {
    CGSize imgSize;
    float newWidth = image.size.width;
    float newHeight = image.size.height;
    float max = longEdge ? longEdge : MAX(newWidth, newHeight);
    float scaleFactor = max / MAX(newWidth, newHeight);
    if (newWidth > newHeight) {
        newWidth = max;
        newHeight = newHeight * scaleFactor;
    } else {
        newHeight = max;
        newWidth = newWidth * scaleFactor;
    }
    imgSize = CGSizeMake(newWidth, newHeight);

    UIImage *newImage = [ImageStore imageWithImage:image scaledToSizeWithSameAspectRatio:imgSize];
    return newImage;
}


- (void)destroy:(NSString *)key
{
    if (!key) {
        return;
    }
    [self.dictionary removeObjectForKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:key] error:NULL];
    
    for (int size = 1; size <= ImageStoreLargeSize; size++) {
        [self.dictionary removeObjectForKey:[self keyForKey:key forSize:size]];
        [[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:[self keyForKey:key forSize:size]] error:NULL];
    }
}

- (NSString *)createKey {
    return [[NSUUID UUID] UUIDString];
}

- (NSString *)pathForKey:(NSString *)key
{
    return [self pathForKey:key forSize:ImageStoreLargeSize];
}

- (NSString *)pathForKey:(NSString *)key forSize:(int)size
{
    NSString *imgKey = [self keyForKey:key forSize:size];
    
    if (size == ImageStoreLargeSize) {
        // try the nonexpiring cache
        if ([[self nonexpiringImageCache] diskImageExistsWithKey:imgKey]) {
            return [[self nonexpiringImageCache] defaultCachePathForKey:imgKey];
        }
    }
    
    // trying the default cache
    if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:imgKey]) {
        return [[SDImageCache sharedImageCache] defaultCachePathForKey:imgKey];
    } else {
        // try the old path
        NSString *oldPath = [self oldPathForKey:key forSize:size];
        UIImage *img = [UIImage imageWithContentsOfFile:oldPath];
        if (img) {
            [[SDImageCache sharedImageCache] storeImage:img forKey:imgKey];
            // delete the old path
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
            // return the new cache path
            return [[SDImageCache sharedImageCache] defaultCachePathForKey:imgKey];
        }
    }
    
    return nil;
}

- (void)makeExpiring:(NSString *)imgKey {
    if ([[self nonexpiringImageCache] diskImageExistsWithKey:imgKey]) {
        // fetch the image from the non-expiring cache
        UIImage *image = [[self nonexpiringImageCache] imageFromDiskCacheForKey:imgKey];
        
        // store in the default cache
        [[SDImageCache sharedImageCache] storeImage:image forKey:imgKey];
        
        // delete from the non-expiring cache
        [[self nonexpiringImageCache] removeImageForKey:imgKey fromDisk:TRUE];
    }
}

- (NSString *)oldPathForKey:(NSString *)key forSize:(int)size {
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *photoDirPath = [docDir stringByAppendingPathComponent:@"photos"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:photoDirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:photoDirPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    return [NSString stringWithFormat:@"%@.jpg",
            [photoDirPath stringByAppendingPathComponent:
             [self keyForKey:key forSize:size]]];
}

- (NSString *)keyForKey:(NSString *)key forSize:(int)size
{
    NSString *str;
    switch (size) {
        case ImageStoreSquareSize:
            str = [NSString stringWithFormat:@"%@-square", key];
            break;
        case ImageStoreSmallSize:
            str = [NSString stringWithFormat:@"%@-small", key];
            break;
        case ImageStoreMediumSize:
            str = [NSString stringWithFormat:@"%@-medium", key];
            break;
        case ImageStoreLargeSize:
            str = [NSString stringWithFormat:@"%@-large", key];
            break;
        default:
            str = key;
            break;
    }
    return str;
}

- (void)clearCache
{
    [dictionary removeAllObjects];
}

- (void)clearCache:(NSNotification *)note
{
    [self clearCache];
}

// Adapted from http://stackoverflow.com/questions/1282830/uiimagepickercontroller-uiimage-memory-and-more
// this code has numerous authors, please see stackoverflow for them all
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize
{  
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    // don't scale up
    if (targetSize.width > width || targetSize.height > height) {
        targetWidth = width;
        targetHeight = height;
    }
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        }
        else {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        }
        else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }     
    
    CGImageRef imageRef = [sourceImage CGImage];
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    
    if (bitmapInfo == kCGImageAlphaNone) {
        bitmapInfo = kCGImageAlphaNoneSkipLast;
    }
    
    CGContextRef bitmap;
    bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
    
    // In the right or left cases, we need to switch scaledWidth and scaledHeight,
    // and also the thumbnail point
    if (sourceImage.imageOrientation == UIImageOrientationLeft) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
        CGFloat translation;
        if (targetWidth == targetHeight) {
            translation = -targetHeight;
        } else {
            translation = -scaledHeight;
        }
        
        CGContextRotateCTM (bitmap, radians(90));
        CGContextTranslateCTM (bitmap, 0, translation);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationRight) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
        CGFloat translation;
        if (targetWidth == targetHeight) {
            translation = -targetWidth;
        } else {
            translation = -scaledWidth;
        }
        
        CGContextRotateCTM (bitmap, radians(-90));
        CGContextTranslateCTM (bitmap, translation, 0);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationUp) {
        // NOTHING
    } else if (sourceImage.imageOrientation == UIImageOrientationDown) {
        CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
        CGContextRotateCTM (bitmap, radians(-180.));
    }
    
    CGContextDrawImage(bitmap, CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledWidth, scaledHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    CGImageRelease(ref);
        
    return newImage; 
}

- (NSString *)urlStringForKey:(NSString *)key forSize:(int)size
{
    return [NSString stringWithFormat:@"documents://photos/%@.jpg", [self keyForKey:key forSize:size]];
}

- (UIImage *)iconicTaxonImageForName:(NSString *)name
{
    NSString *iconicTaxonName = name ? [name lowercaseString] : @"unknown";
    NSString *key = [NSString stringWithFormat:@"ic_%@", iconicTaxonName];
    return [UIImage imageNamed:key];
}

@end
