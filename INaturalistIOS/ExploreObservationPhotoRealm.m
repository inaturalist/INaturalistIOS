//
//  ExploreObservationPhotoRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreObservationPhotoRealm.h"
#import "ImageStore.h"
#import "ExploreObservationRealm.h"

@implementation ExploreObservationPhotoRealm

- (instancetype)initWithMantleModel:(ExploreObservationPhoto *)model {
    if (self = [super init]) {
        self.observationPhotoId = model.observationPhotoId;
        self.position = model.position;
        self.uuid = model.uuid;
        self.licenseCode = model.licenseCode;
        self.urlString = model.url.absoluteString;
        self.attribution = model.attribution;
        self.photoKey = nil;
        self.syncedAt = model.syncedAt;
        self.updatedAt = model.updatedAt;
    }
    
    return self;
}

+ (NSString *)primaryKey {
    return @"uuid";
}

- (NSURL *)url {
    return [NSURL URLWithString:self.urlString];
}

- (NSURL *)largePhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"large"]];
}

- (NSURL *)mediumPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"medium"]];
}

- (NSURL *)smallPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"small"]];
}

- (NSURL *)thumbPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"thumb"]];
}

- (NSURL *)squarePhotoUrl {
    return self.url;
}

- (NSString *)urlStringForSize:(NSString *)size {
    return [self.urlString stringByReplacingOccurrencesOfString:@"square"
                                                     withString:size];
}

- (BOOL)needsSync {
    return self.syncedAt == nil || [self.syncedAt timeIntervalSinceDate:self.updatedAt] < 0;
}

- (BOOL)needsUpload {
    return [self needsSync];
}

+ (NSString *)endpointName {
    return @"observation_photos";
}

-(NSInteger)inatRecordId {
    return self.observationPhotoId;
}

- (void)setInatRecordId:(NSInteger)inatRecordId {
    self.observationPhotoId = inatRecordId;
}

- (NSString *)fileUploadParameter {
    NSString *path = [[ImageStore sharedImageStore] pathForKey:self.photoKey
                                                       forSize:ImageStoreLargeSize];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // if we can't get the large, try the small
    if (!path || ! [fm fileExistsAtPath:path]) {
        path = [[ImageStore sharedImageStore] pathForKey:self.photoKey
                                                 forSize:ImageStoreSmallSize];
    }
    
    // if we don't have any files for this obs photo, it's not in the ImageStore
    if (!path || ![fm fileExistsAtPath:path]) {
        return nil;
    } else {
        return path;
    }
}

- (NSDictionary *)uploadableRepresentation {
    NSDictionary *mapping = @{
                              @"position": @"observation_photo[position]",
                              @"uuid": @"observation_photo[uuid]",
                              };
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    for (NSString *key in mapping) {
        if ([self valueForKey:key]) {
            NSString *mappedName = mapping[key];
            mutableParams[mappedName] = [self valueForKey:key];
        }
    }
    
    ExploreObservationRealm *obs = [[self observations] firstObject];
    mutableParams[@"observation_photo[observation_id]"] = @(obs.inatRecordId);
    
    // return an immutable copy
    return [NSDictionary dictionaryWithDictionary:mutableParams];
}

+ (NSDictionary *)linkingObjectsProperties {
    return @{
             @"observations": [RLMPropertyDescriptor descriptorWithClass:ExploreObservationRealm.class
                                                            propertyName:@"observationPhotos"]
             };
}

@end
