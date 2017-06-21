//
//  ImageStore.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

enum {
    ImageStoreOriginalSize = 0,
    ImageStoreSquareSize = 1,
    ImageStoreSmallSize = 2,
    ImageStoreMediumSize = 3,
    ImageStoreLargeSize = 4
};

#define radians( degrees ) ( degrees * M_PI / 180 )

@interface ImageStore : NSObject
@property (nonatomic, strong) NSMutableDictionary *dictionary;
+ (ImageStore *)sharedImageStore;
- (UIImage *)find:(NSString *)key forSize:(int)size;
- (BOOL)storeImage:(UIImage *)image forKey:(NSString *)key error:(NSError **)error;
- (void)destroy:(NSString *)key;
- (NSString *)createKey;
- (NSString *)pathForKey:(NSString *)key;
- (NSString *)pathForKey:(NSString *)key forSize:(int)size;
- (NSString *)keyForKey:(NSString *)key forSize:(int)size;
- (UIImage *)iconicTaxonImageForName:(NSString *)name;
- (void)makeExpiring:(NSString *)imgKey;
- (NSString *)usageStatsString;
- (void)clearEntireStore;
+ (NSArray *)assetCollectionSubtypes;
+ (UIImage *)imageWithImage:(UIImage *)image squashedToFillSize:(CGSize)size;
@end
