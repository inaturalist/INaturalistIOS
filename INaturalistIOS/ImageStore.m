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
        CGSize imageSize = [[asset defaultRepresentation] dimensions];
        CGFloat longestSide = imageSize.width > imageSize.height ? imageSize.width : imageSize.height;
        CGFloat scale = [[asset defaultRepresentation] scale];
        
        if (longestSide > INATURALIST_ORG_MAX_PHOTO_EDGE) {
            scale = INATURALIST_ORG_MAX_PHOTO_EDGE / longestSide;
        }
        
        // resize with CGImage is fast enough for us
        UIImage *resized = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]
                                               scale:scale
                                         orientation:[[asset defaultRepresentation] orientation]];
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
    if (!imgKey) { return; }
    
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
