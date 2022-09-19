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
#import <ImageIO/ImageIO.h>
#import <Photos/Photos.h>

#import "ImageStore.h"
#import "Analytics.h"

#define INATURALIST_ORG_MAX_PHOTO_EDGE      2048

@interface ImageStore ()
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

+ (NSArray *)assetCollectionSubtypes {
    return @[
             @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
             @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
             @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
             @(PHAssetCollectionSubtypeSmartAlbumBursts),
             @(PHAssetCollectionSubtypeSmartAlbumFavorites),
             @(PHAssetCollectionSubtypeAlbumRegular),
             @(PHAssetCollectionSubtypeAlbumImported),
             @(PHAssetCollectionSubtypeAlbumCloudShared),
             @(PHAssetCollectionSubtypeAlbumSyncedAlbum),
             ];
}

- (instancetype)init {
    if (self = [super init]) {
        [self setDictionary:[[NSMutableDictionary alloc] init]];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(clearMemoryCache:)
                                                   name:UIApplicationDidReceiveMemoryWarningNotification
                                                 object:nil];
    }
    return self;
}

- (UIImage *)find:(NSString *)key {
    return [self find:key forSize:ImageStoreLargeSize];
}

- (UIImage *)find:(NSString *)key forSize:(int)size {
    NSString *sizedKey = [self keyForKey:key forSize:size];
    
    // prefer the non-expiring version
    UIImage *image = [self findInNonExpiringCacheSizedKey:sizedKey];
    if (!image) {
        image = [self findInExpiringCacheSizedKey:sizedKey];
    }
    return image;
}

- (BOOL)storeImage:(UIImage *)image forKey:(NSString *)key error:(NSError **)error {
    [[Analytics sharedClient] debugLog:@"IMAGE STORE: begin"];

    @autoreleasepool {
        // large = fullsize image but truncated to 2048x2048 pixels max (aspect ratio scaled)
        CGSize imageSize = image.size;
        CGFloat longestSide = MAX(imageSize.width, imageSize.height);
        CGFloat scale = 1;
        
        if (longestSide > INATURALIST_ORG_MAX_PHOTO_EDGE) {
            scale = INATURALIST_ORG_MAX_PHOTO_EDGE / longestSide;
        }
        
        // resize with CGImage is fast enough for us
        UIImage *resized = [UIImage imageWithCGImage:image.CGImage
                                               scale:scale
                                         orientation:image.imageOrientation];
        NSString *largeKey = [self keyForKey:key forSize:ImageStoreLargeSize];
        [self storeInNonExpiringCacheImage:resized withSizedKey:largeKey];
    }
    
    @autoreleasepool {
        // small = 640x640
        CGSize imageSize = image.size;
        CGFloat longestSide = MAX(imageSize.width, imageSize.height);
        CGFloat scale = 1;
        
        if (longestSide > 640.0) {
            scale = 640.0 / longestSide;
        }
        
        // resize with CGImage is fast enough for us
        UIImage *resized = [UIImage imageWithCGImage:image.CGImage
                                               scale:scale
                                         orientation:image.imageOrientation];

        NSString *smallKey = [self keyForKey:key forSize:ImageStoreSmallSize];
        [self storeInNonExpiringCacheImage:resized withSizedKey:smallKey];
    }
    
    @autoreleasepool {
        UIImage *thumb = [[self class] imageWithImage:image scaledToFillSize:CGSizeMake(128, 128)];
        NSString *squareKey = [self keyForKey:key forSize:ImageStoreSquareSize];
        [self storeInNonExpiringCacheImage:thumb withSizedKey:squareKey];
    }
    
    [[Analytics sharedClient] debugLog:@"IMAGE STORE: done"];
    return YES;
}

+ (UIImage *)imageWithImage:(UIImage *)image squashedToFillSize:(CGSize)size {
    CGRect imageRect = CGRectMake(0, 0, size.width, size.height);    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size {
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)destroy:(NSString *)baseKey {
    if (!baseKey) {
        return;
    }
    [self.dictionary removeObjectForKey:baseKey];
    [[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:baseKey] error:nil];
    
    for (int size = 1; size <= ImageStoreLargeSize; size++) {
        NSString *sizedKey = [self keyForKey:baseKey forSize:size];
        [self.dictionary removeObjectForKey:sizedKey];
        [self deleteFromNonExpiringCacheSizedKey:sizedKey];
        [self deleteFromExpiringCacheSizedKey:sizedKey];
    }
}

- (NSString *)createKey {
    return [[NSUUID UUID] UUIDString];
}

- (NSString *)pathForKey:(NSString *)key {
    return [self pathForKey:key forSize:ImageStoreLargeSize];
}

- (NSString *)pathForKey:(NSString *)key forSize:(int)size {
    NSString *sizedKey = [self keyForKey:key forSize:size];
    
    // prefer nonexpiring
    NSString *path = [self pathInNonExpiringCacheSizedKey:sizedKey];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    } else {
        return [self pathInExpiringCacheSizedKey:sizedKey];
    }    
}

- (void)makeExpiring:(NSString *)imgKey {
    if (!imgKey) { return; }
    
    NSString *largeKey = [self keyForKey:imgKey forSize:ImageStoreLargeSize];
    NSString *smallKey = [self keyForKey:imgKey forSize:ImageStoreSmallSize];
    NSString *thumbKey = [self keyForKey:imgKey forSize:ImageStoreSquareSize];
    
    for (NSString *sizedKey in @[ largeKey, smallKey, thumbKey ]) {
        NSData *data = [self dataForNonExpiringCacheSizedKey:sizedKey];
        // stash this synchronously
        [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:sizedKey];
        [self deleteFromNonExpiringCacheSizedKey:sizedKey];
    }
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

#pragma mark - cache clearing methods

- (void)clearMemoryCache {
    [dictionary removeAllObjects];
}

- (void)clearMemoryCache:(NSNotification *)note {
    [self clearMemoryCache];
}

- (void)clearEntireStore {
    [self clearMemoryCache];
    
    // clear the expiring cache
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    
    // clear the non-expiring cache
    NSString *photoDirPath = [self nonExpiringCacheBasePath];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:photoDirPath error:nil];
    for (NSString *fileName in files) {
        NSString *filePath = [photoDirPath stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    [[NSFileManager defaultManager] removeItemAtPath:photoDirPath error:nil];
}

#pragma mark -

- (NSString *)usageStatsString {
    static NSNumberFormatter *numberFormatter = nil;
    if (!numberFormatter) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        numberFormatter.groupingSize = 3;
        numberFormatter.groupingSeparator = @",";
    }
    
    NSString *sdSize = [numberFormatter stringFromNumber:@([[SDImageCache sharedImageCache] getSize])];
    NSString *sdCount = [numberFormatter stringFromNumber:@([[SDImageCache sharedImageCache] getDiskCount])];
    NSString *sdCacheStats = [NSString stringWithFormat:@"SDImageCache: %@ for %@ files",
                              sdSize, sdCount];
    
    NSString *photoDirPath = [self nonExpiringCacheBasePath];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:photoDirPath error:nil];
    NSString *photosCount = [numberFormatter stringFromNumber:@([files count])];

    unsigned long long int allPhotosSize = 0;
    for (NSString *fileName in files) {
        NSString *filePath = [photoDirPath stringByAppendingPathComponent:fileName];
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        allPhotosSize += [fileDictionary fileSize];
    }
    NSString *photosSize = [numberFormatter stringFromNumber:@(allPhotosSize)];

    NSString *photoCacheStats = [NSString stringWithFormat:@"Un-Uploaded Photos: %@ for %@ files",
                                 photosSize, photosCount];
    return [NSString stringWithFormat:@"%@ - %@", sdCacheStats, photoCacheStats];
}

- (UIImage *)iconicTaxonImageForName:(NSString *)name
{
    NSString *iconicTaxonName = name ? [name lowercaseString] : @"unknown";
    NSString *key = [NSString stringWithFormat:@"ic_%@", iconicTaxonName];
    return [UIImage imageNamed:key];
}

#pragma mark - Expiring Cache Methods

- (UIImage *)findInExpiringCacheSizedKey:(NSString *)sizedKey {
    return [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:sizedKey];
}

- (NSString *)pathInExpiringCacheSizedKey:(NSString *)sizedKey {
    return [[SDImageCache sharedImageCache] defaultCachePathForKey:sizedKey];
}

- (void)storeInExpiringCacheImage:(UIImage *)image withSizedKey:(NSString *)sizedKey {
    [[SDImageCache sharedImageCache] storeImage:image forKey:sizedKey toDisk:YES completion:nil];
}

- (void)deleteFromExpiringCacheSizedKey:(NSString *)sizedKey {
    [[SDImageCache sharedImageCache] removeImageForKey:sizedKey fromDisk:YES withCompletion:nil];
}

#pragma mark - Non-expiring Cache Methods

- (UIImage *)findInNonExpiringCacheSizedKey:(NSString *)sizedKey {
    return [UIImage imageWithContentsOfFile:[self pathInNonExpiringCacheSizedKey:sizedKey]];
}

- (NSData *)dataForNonExpiringCacheSizedKey:(NSString *)sizedKey {
    return [NSData dataWithContentsOfFile:[self pathInNonExpiringCacheSizedKey:sizedKey]];
}

- (NSString *)pathInNonExpiringCacheSizedKey:(NSString *)sizedKey {
    NSString *filePath = [[self nonExpiringCacheBasePath] stringByAppendingPathComponent:sizedKey];
    return filePath;
}

- (BOOL)storeInNonExpiringCacheImage:(UIImage *)image withSizedKey:(NSString *)sizedKey {
    NSString *path = [self pathInNonExpiringCacheSizedKey:sizedKey];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
    return [imageData writeToFile:path atomically:YES];
}

- (void)deleteFromNonExpiringCacheSizedKey:(NSString *)sizedKey {
    NSString *path = [self pathInNonExpiringCacheSizedKey:sizedKey];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (NSString *)nonExpiringCacheBasePath {
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *photoDirPath = [docDir stringByAppendingPathComponent:@"photos"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:photoDirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:photoDirPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return photoDirPath;
}

- (void)cleanupImageStoreUsingValidPhotoKeys:(NSArray *)validPhotoKeys
                             syncedPhotoKeys:(NSArray *)syncedPhotoKeys
                        allowedExecutionTime:(NSTimeInterval)allowedExecutionSeconds {
    
    NSDate *beginCleanupDate = [NSDate date];
        
    // clear the non-expiring cache
    NSString *photoDirPath = [self nonExpiringCacheBasePath];
    NSError *listError = nil;
    NSArray *allNonExpiringFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:photoDirPath error:&listError];
    if (listError) { return; }
    
    NSInteger deletedCount = 0;
    NSInteger checkedCount = 0;
    NSInteger makeExpiredCount = 0;
    
    for (NSString *nonExpiringFilename in allNonExpiringFiles) {
        NSDate *now = [NSDate date];
        NSTimeInterval timeCleaningSoFar = [now timeIntervalSinceDate:beginCleanupDate];
        
        if (timeCleaningSoFar >= allowedExecutionSeconds) {
            break;
        }
        
        if (nonExpiringFilename.length <= 37) { continue; }
        
        NSString *key = nil;
        // 92E177B0-0B8F-47C0-B13D-7D9A3041562A-large
        NSRange sizeRange = NSMakeRange(36, nonExpiringFilename.length - 36);
        key = [nonExpiringFilename stringByReplacingCharactersInRange:sizeRange
                                                           withString:@""];
        
        // simple sanity checks
        if (!key) { break; }
        if (key.length == 0) { break; }
        
        NSString *filePath = [photoDirPath stringByAppendingPathComponent:nonExpiringFilename];
        
        // don't delete anything less than 24 hours old - should make sure if
        // you start an obs, then close and reopen the app to do something else,
        // we don't delete the photo for the in-progress observation. basically, the
        // obs photo may not have been inserted into realm yet, so it's not safe
        // to just delete it.
        NSError *attrError = nil;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                                               error:&attrError];
        if (attrError) { break; }
        NSDate *modDate = [attrs objectForKey:NSFileCreationDate];
        if (!modDate) { break; }
        NSTimeInterval since = [[NSDate date] timeIntervalSinceDate:modDate];
        if (since < 60 * 60 * 24) { break; }
        
        // if it's not in the valid photo key list, it's not a photo we need
        // to care about anymore - we don't have an observation photo for it
        // so delete this photo
        if (![validPhotoKeys containsObject:key]) {
            // safe to delete this file
            NSString *filePath = [photoDirPath stringByAppendingPathComponent:nonExpiringFilename];
            NSError *deleteError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&deleteError];
            if (deleteError) { break; }
            
            deletedCount += 1;
        }
        
        // if we've synced this observation photo, then the photo can safely be moved
        // to the SDImageCache where it can be expired based on date & space used
        if ([syncedPhotoKeys containsObject:key]) {
            [self makeExpiring:key];
            
            makeExpiredCount += 1;
        }
        
        checkedCount += 1;
    }
    
    NSDate *now = [NSDate date];
    NSTimeInterval cleanupExecutionSecondsUsed = [now timeIntervalSinceDate:beginCleanupDate];
}


@end
