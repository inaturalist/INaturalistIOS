//
//  PhotoSource.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "PhotoSource.h"

@implementation PhotoSource
@synthesize title = _title;
@synthesize photos = _photos;

- (id)initWithPhotos:(NSArray *)photos title:(NSString *)title
{
    self = [super init];
    if (self) {
        self.photos = [[NSMutableArray alloc] initWithArray:photos];
        self.title = title;
        for (int i = 0; i < photos.count; i++) {
            id<TTPhoto> p = [self.photos objectAtIndex:i];
            p.photoSource = self;
            if ([p respondsToSelector:@selector(setIndex:)]) {
                [p setIndex:i];
            }
        }
    }
    return self;
}

- (void)removePhoto:(id<TTPhoto>)photo
{
//    NSLog(@"removing photo %@", photo);
    [self.photos removeObject:photo];
    for (int i = 0; i < self.photos.count; i++) {
        id<TTPhoto> p = [self.photos objectAtIndex:i];
        [p setIndex:i];
    }
}

#pragma mark TTModel
- (BOOL)isLoading
{
    return FALSE;
}
- (BOOL)isLoaded
{
    return TRUE;
}

#pragma mark TTPhotoSource
- (NSInteger)numberOfPhotos
{
    return self.photos.count;
}

- (NSInteger)maxPhotoIndex
{
    return self.photos.count - 1;
}

- (id<TTPhoto>)photoAtIndex:(NSInteger)index
{
    // for some reason TTThumbViewController will ask for photos beyond the maxPhotoIndex, 
    // so we need to check for indices out of range
    if (index > self.maxPhotoIndex) {
        return nil;
    } else {
        return [self.photos objectAtIndex:index];
    }
}
@end
