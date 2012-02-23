//
//  PhotoSource.m
//  INaturalistIOS
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
        self.photos = photos;
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
    return [self.photos objectAtIndex:index];
}
@end
