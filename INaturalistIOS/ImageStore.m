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

#import "ImageStore.h"
#import "Analytics.h"

@interface ImageStore () {
    NSOperationQueue *resizeQueue;
}
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
    return [self find:key forSize:0];
}

- (UIImage *)find:(NSString *)key forSize:(int)size
{
    NSString *imgKey = [self keyForKey:key forSize:size];
    UIImage *image = [self.dictionary objectForKey:imgKey];
    if (!image) {
        image = [UIImage imageWithContentsOfFile:[self pathForKey:imgKey]];
        if (image) {
            [dictionary setValue:image forKey:imgKey];
        } else {
            NSLog(@"Error: couldn't find image file for %@", imgKey);
        }
    }
    return image;
}

- (BOOL)storeAsset:(ALAsset *)asset forKey:(NSString *)key error:(NSError *__autoreleasing *)storeError {
    [[Analytics sharedClient] debugLog:@"ASSET STORE: begin"];
    
    NSString *filePath = [self pathForKey:key];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath])
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        [[Analytics sharedClient] debugLog:@"ASSET STORE: fatal no filehandle"];
        return NO;
    }
    long long assetSize = asset.defaultRepresentation.size;

    @autoreleasepool {
        uint8_t buffer[64<<10];
        for (long long offset=0; offset<assetSize; offset+=sizeof(buffer)) {
            NSUInteger length = MIN(sizeof(buffer), assetSize-offset);
            NSError *error = nil;
            [asset.defaultRepresentation getBytes:buffer
                                       fromOffset:offset
                                           length:length
                                            error:&error];
            if (error) {
                NSString *debugMsg = [NSString stringWithFormat:@"ASSET STORE: error %@", error.localizedDescription];
                [[Analytics sharedClient] debugLog:debugMsg];
                *storeError = [error copy];
                fileHandle = nil;
                break;
            }
            @try {
                [fileHandle writeData:[NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:NO]];
            }
            @catch (NSException *exception) {
                fileHandle = nil;
                break;
            }
        }
    }
    
    if (fileHandle == nil) {
        [[Analytics sharedClient] debugLog:@"ASSET STORE: fatal no filehandle"];
        return NO;
    }
    
    [fileHandle truncateFileAtOffset:assetSize];
    [fileHandle closeFile];

    float screenMax = MAX([UIScreen mainScreen].bounds.size.width,
                          [UIScreen mainScreen].bounds.size.height);
    
    // "small" == asset fullscreen
    @autoreleasepool {
        UIImage *fullScreen = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
        NSData *data = UIImageJPEGRepresentation(fullScreen, 1.0f);
        NSString *path = [self pathForKey:key forSize:ImageStoreSmallSize];
        NSError *saveError = nil;
        [data writeToFile:path options:NSDataWritingAtomic error:&saveError];
        if (saveError) {
            NSString *debugMsg = [NSString stringWithFormat:@"ASSET STORE: fatal save small %@", saveError.localizedDescription];
            [[Analytics sharedClient] debugLog:debugMsg];
            *storeError = [saveError copy];
            return NO;
        }
    }
    
    // "square" == asset square
    UIImage *thumbnail = [UIImage imageWithCGImage:asset.thumbnail];
    NSData *data = UIImageJPEGRepresentation(thumbnail, 1.0f);
    NSString *path = [self pathForKey:key forSize:ImageStoreSquareSize];
    NSError *saveError = nil;
    [data writeToFile:path options:NSDataWritingAtomic error:&saveError];
    if (saveError) {
        NSString *debugMsg = [NSString stringWithFormat:@"ASSET STORE: fatal save thumbnail %@", saveError.localizedDescription];
        [[Analytics sharedClient] debugLog:debugMsg];
        *storeError = [saveError copy];
        return NO;
    }
    
    // generate "large" on a single-threaded background queue
    [resizeQueue addOperationWithBlock:^{
        @autoreleasepool {
            [self generateImageWithParams:@{
                                            @"key": key,
                                            @"size": @(ImageStoreLargeSize),
                                            @"longEdge": @(2.0 * screenMax),
                                            @"compression": @(1.0),
                                            }
                                    error:nil];
        }
    }];
    
    [[Analytics sharedClient] debugLog:@"ASSET STORE: done"];
    return YES;
}

- (BOOL)generateImageWithParams:(NSDictionary *)params error:(NSError **)generatorError {
    NSString *key = [params objectForKey:@"key"];
    if (!key)
        return NO;
    
    int size = [[params objectForKey:@"size"] intValue];
    if (!size) size = ImageStoreOriginalSize;
    
    NSString *sizedKey = [self keyForKey:key forSize:size];
    
    CGFloat longEdge = [[params objectForKey:@"longEdge"] floatValue];
    float compression = [[params objectForKey:@"compression"] floatValue];
    if (!compression || compression == 0) compression = 1.0;
    
    UIImage *image = [self find:key];
    if (!image) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"ASSET STORE: failed on size %d", size]];
        return NO;
    }
    
    CGSize imgSize;
    if (size == ImageStoreSquareSize) {
        imgSize = CGSizeMake(75, 75);
    } else {
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
    }
    
    UIImage *newImage = [ImageStore imageWithImage:image scaledToSizeWithSameAspectRatio:imgSize];
    if (!newImage) {
        [[Analytics sharedClient] debugLog:@"ASSET STORE: couldn't scale"];
        return NO;
    }
    
    [self.dictionary setValue:newImage forKey:sizedKey];
    NSString *filePath = [self pathForKey:sizedKey];
    NSData *data = UIImageJPEGRepresentation(newImage, compression);
    
    if (!data) {
        [[Analytics sharedClient] debugLog:@"ASSET STORE: no jpeg representation"];
        return NO;
    }
    
    NSError *writeError;
    [data writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
    if (writeError) {
        NSString *debugMsg = [NSString stringWithFormat:@"ASSET STORE: write error %@", writeError.localizedDescription];
        [[Analytics sharedClient] debugLog:debugMsg];
        *generatorError = [writeError copy];
        return NO;
    }
    
    return YES;
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
    return [self pathForKey:key forSize:0];
}

- (NSString *)pathForKey:(NSString *)key forSize:(int)size
{
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *photoDirPath = [docDir stringByAppendingPathComponent:@"photos"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:photoDirPath]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:photoDirPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
    return [NSString stringWithFormat:@"%@.jpg",
            [photoDirPath stringByAppendingPathComponent:
             [self keyForKey:key forSize:size]]];
}

- (BOOL)fileExistsForKey:(NSString *)key andSize:(int)size
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[ self pathForKey:key forSize:size]];
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
