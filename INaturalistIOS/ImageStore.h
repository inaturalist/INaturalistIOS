//
//  ImageStore.h
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    ImageStoreSquareSize = 1,
    ImageStoreSmallSize = 2
};

#define radians( degrees ) ( degrees * M_PI / 180 )

@interface ImageStore : NSObject
@property (nonatomic, strong) NSMutableDictionary *dictionary;
+ (ImageStore *)sharedImageStore;
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize;
- (UIImage *)find:(NSString *)key;
- (UIImage *)find:(NSString *)key forSize:(int)size;
- (void)store:(UIImage *)image forKey:(NSString *)key;
- (void)destroy:(NSString *)key;
- (NSString *)createKey;
- (NSString *)pathForKey:(NSString *)key;
- (NSString *)pathForKey:(NSString *)key forSize:(int)size;
- (NSString *)keyForKey:(NSString *)key forSize:(int)size;
- (void)generateSmallImageForKey:(NSString *)key;
- (void)generateSquareImageForKey:(NSString *)key;
- (void)clearCache;
@end
