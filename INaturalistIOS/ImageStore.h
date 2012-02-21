//
//  ImageStore.h
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageStore : NSObject
@property (nonatomic, strong) NSMutableDictionary *dictionary;
+ (ImageStore *)sharedImageStore;
- (UIImage *)find:(NSString *)key;
- (void)store:(UIImage *)image forKey:(NSString *)key;
- (void)destroy:(NSString *)key;
- (NSString *)createKey;
- (NSString *)pathForKey:(NSString *)key;
@end
