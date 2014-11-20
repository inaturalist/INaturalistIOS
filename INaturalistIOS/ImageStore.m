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

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ImageStore.h"

#import <Photos/Photos.h>

@interface UIImage (Scaled)
- (UIImage *)scaledToSize:(CGSize)size;
@end

@implementation ImageStore
@synthesize dictionary;

// singleton
+ (ImageStore *)sharedImageStore
{
    static dispatch_once_t onceToken;
    static ImageStore *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super new];
        
        sharedInstance.dictionary = [NSMutableDictionary dictionary];
        sharedInstance.assetsLibrary = [[ALAssetsLibrary alloc] init];
        
        [NSNotificationCenter.defaultCenter addObserver:sharedInstance
                                               selector:@selector(clearCache:)
                                                   name:UIApplicationDidReceiveMemoryWarningNotification
                                                 object:nil];

    });
    
    return sharedInstance;
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



- (void)storeAsset:(NSURL *)assetUrl forKey:(NSString *)key completion:(void (^)(NSError *error))completion {

    if (NSClassFromString(@"PHAsset")) {
        
        // use the iOS 8 photo framework to fetch the image, which may be in the user's photostream in iCloud
        PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:@[assetUrl] options:nil];
        PHAsset *asset = result.firstObject;
        
        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                          options:nil
                                                    resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                        
                                                        // original
                                                        NSString *fullPath = [self pathForKey:key];
                                                        [imageData writeToFile:fullPath atomically:YES];
                                                        
                                                        // generate cutdowns
                                                        UIImage *original = [UIImage imageWithData:imageData];
                                                        
                                                        // large > small > square thumbnail
                                                        UIImage *large = [self cutdownFromImage:original size:ImageStoreLargeSize];
                                                        [self saveImage:large key:key size:ImageStoreLargeSize];
                                                        
                                                        UIImage *small = [self cutdownFromImage:large size:ImageStoreSmallSize];
                                                        [self saveImage:small key:key size:ImageStoreSmallSize];

                                                        UIImage *thumbnail = [self cutdownFromImage:small size:ImageStoreSquareSize];
                                                        [self saveImage:thumbnail key:key size:ImageStoreSquareSize];

                                                        completion(nil);
                                                    }];
        
    } else {
        
        // use the iOS 7 ALAssetsLibrary framework to fetch the image
        [self.assetsLibrary assetForURL:assetUrl resultBlock:^(ALAsset *asset) {
            
            // generate cutdowns
            UIImage *fullScreen = [UIImage imageWithCGImage:[asset.defaultRepresentation fullScreenImage]];
            
            // large > small > square thumbnail
            UIImage *large = [self cutdownFromImage:fullScreen size:ImageStoreLargeSize];
            [self saveImage:large key:key size:ImageStoreLargeSize];
            
            UIImage *small = [self cutdownFromImage:large size:ImageStoreSmallSize];
            [self saveImage:small key:key size:ImageStoreSmallSize];
            
            UIImage *thumbnail = [self cutdownFromImage:small size:ImageStoreSquareSize];
            [self saveImage:thumbnail key:key size:ImageStoreSquareSize];
            
            // safe to call the completion, the UI operates on the above cutdowns
            completion(nil);
            
            // original
            // Open the temporary file for writing
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *fullPath = [self pathForKey:key];
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fullPath];
                ALAssetRepresentation *assetRepresentation = asset.defaultRepresentation;
                long assetSize = assetRepresentation.size;
                
                if (fileHandle) {
                    // Copy the default representation data into the temporary file
                    @autoreleasepool {
                        uint8_t buffer[65536];
                        for (long long offset = 0; offset < assetSize; offset += sizeof(buffer)) {
                            NSUInteger length = MIN(sizeof(buffer), assetSize-offset);
                            NSError *error = nil;
                            [assetRepresentation getBytes:buffer fromOffset:offset length:length error:&error];
                            if (error) {
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
                }
                
                // If the file handle is not valid, an error must have occurred above
                if (!fileHandle) {
                    NSLog(@"error writing FS asset: %@", assetUrl);
                }
                
                // Truncate the temporary file (in case
                // it was larger before) and close it
                [fileHandle truncateFileAtOffset:assetSize];
                [fileHandle closeFile];
            });
        } failureBlock:^(NSError *error) {
            NSLog(@"couldn't store asset %@", error.localizedDescription);
            completion(error);
        }];
    }
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

- (NSString *)createKey
{
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

- (NSString *)urlStringForKey:(NSString *)key forSize:(int)size
{
    return [NSString stringWithFormat:@"documents://photos/%@.jpg", [self keyForKey:key forSize:size]];
}

// helper to calculate what CGSize to crop an image to, for a given ImageStoreSize
- (CGSize)croppedSizeForImageSized:(CGSize)originalSize imageStoreSize:(ImageStoreSize)imageStoreSize {
    if (imageStoreSize == ImageStoreSquareSize) {
        return CGSizeMake(75, 75);
    } else {
        float newWidth = originalSize.width;
        float newHeight = originalSize.height;
        float max;
        if (imageStoreSize == ImageStoreLargeSize) {
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            max = MAX(screenSize.width, screenSize.height);
        } else if (imageStoreSize == ImageStoreSmallSize) {
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            max = (MAX(screenSize.width, screenSize.height) * 0.5);
        }
        
        float scaleFactor = max / MAX(newWidth, newHeight);
        if (newWidth > newHeight) {
            newWidth = max;
            newHeight = newHeight * scaleFactor;
        } else {
            newHeight = max;
            newWidth = newWidth * scaleFactor;
        }
        return CGSizeMake(newWidth, newHeight);
    }
}

// generates a cutdown for an image with a given ImageStoreSize
- (UIImage *)cutdownFromImage:(UIImage *)sourceImage size:(ImageStoreSize)size {
    CGSize targetSize = [self croppedSizeForImageSized:sourceImage.size imageStoreSize:size];
    return [sourceImage scaledToSize:targetSize];
}

// saves an image into the ImageStore with a given key and ImageStoreSize
- (void)saveImage:(UIImage *)image key:(NSString *)key size:(ImageStoreSize)size {
    NSString *path = [self pathForKey:key forSize:size];
    NSData *jpegData = UIImageJPEGRepresentation(image, 0.8);
    [jpegData writeToFile:path atomically:YES];
}

- (UIImage *)iconicTaxonImageForName:(NSString *)name
{
    NSString *iconicTaxonName = name ? [name lowercaseString] : @"unknown";
    NSString *key = [NSString stringWithFormat:@"iconic_taxon_%@", iconicTaxonName];
    UIImage *img = [self.dictionary objectForKey:key];
    if (!img) {
        img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", key]];
        if (!img) {
            img = [UIImage imageNamed:@"iconic_taxon_unknown.png"];
        }
        [self.dictionary setObject:img forKey:key];
    }
    return img;
}

@end

@implementation UIImage (Scaling)

- (UIImage *)scaledToSize:(CGSize)targetSize {
    // this is memory intensive, so let's clear our autorelease pool quickly
    @autoreleasepool {
        UIGraphicsBeginImageContextWithOptions(targetSize, TRUE, 0.0);
        [self drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
        return UIGraphicsGetImageFromCurrentImageContext();
    }
}
@end
