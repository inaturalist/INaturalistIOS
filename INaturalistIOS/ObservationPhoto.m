//
//  ObservationPhoto.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationPhoto.h"
#import "Observation.h"
#import "ImageStore.h"
#import "DeletedRecord.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation ObservationPhoto

@dynamic largeURL;
@dynamic licenseCode;
@dynamic mediumURL;
@dynamic nativePageURL;
@dynamic nativeRealName;
@dynamic nativeUsername;
@dynamic observationID;
@dynamic originalURL;
@dynamic position;
@dynamic smallURL;
@dynamic squareURL;
@dynamic syncedAt;
@dynamic thumbURL;
@dynamic observation;
@dynamic photoKey;
@dynamic nativePhotoID;
@dynamic uuid;

- (void)prepareForDeletion
{
    [super prepareForDeletion];
    [[ImageStore sharedImageStore] destroy:self.photoKey];
    if (self.syncedAt) {
        DeletedRecord *dr = [DeletedRecord object];
        dr.recordID = self.recordID;
        dr.modelName = NSStringFromClass(self.class);
    }
}

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[ObservationPhoto class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"photo_id", @"photoID",
         @"observation_id", @"observationID",
         @"createdAt", @"createdAt",
         @"updatedAt", @"updatedAt",
         @"position", @"position",
         @"photo.original_url", @"originalURL",
         @"photo.large_url", @"largeURL",
         @"photo.medium_url", @"mediumURL",
         @"photo.small_url", @"smallURL",
         @"photo.thumb_url", @"thumbURL",
         @"photo.square_url", @"squareURL",
         @"photo.native_page_url", @"nativePageURL",
         @"photo.native_photo_id", @"nativePhotoID",
         @"photo.native_username", @"nativeUsername",
         @"photo.native_realname", @"nativeRealName",
         @"photo.license_code", @"licenseCode",
         @"uuid", @"uuid",
         nil];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKManagedObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [RKManagedObjectMapping mappingForClass:[ObservationPhoto class]
                                                         inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultSerializationMapping mapKeyPathsToAttributes:
         @"observationID", @"observation_photo[observation_id]",
         @"position", @"observation_photo[position]",
         @"uuid", @"observation_photo[uuid]",
         nil];
    }
    return defaultSerializationMapping;
}

// checks the associated observation for its recordID
- (NSNumber *)observationID
{
    [self willAccessValueForKey:@"observationID"];
    if (self.observation && self.observation.recordID && (!self.primitiveObservationID || [self.primitiveObservationID intValue] == 0)) {
        [self setPrimitiveObservationID:self.observation.recordID];
    }
    [self didAccessValueForKey:@"observationID"];
    return [self primitiveObservationID];
}

#pragma mark - INatPhoto


- (NSURL *)largePhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *localPath = [[ImageStore sharedImageStore] pathForKey:self.photoKey forSize:ImageStoreLargeSize];

    if (self.photoKey && localPath && [fm fileExistsAtPath:localPath]) {
        return [NSURL fileURLWithPath:localPath];
    } else if (self.largeURL) {
        return [NSURL URLWithString:self.largeURL];
    } else {
        return [self mediumPhotoUrl];
    }
}

- (NSURL *)mediumPhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *localPath = [[ImageStore sharedImageStore] pathForKey:self.photoKey forSize:ImageStoreMediumSize];
    
    if (self.photoKey && localPath && [fm fileExistsAtPath:localPath]) {
        return [NSURL fileURLWithPath:localPath];
    } else if (self.mediumURL) {
        return [NSURL URLWithString:self.mediumURL];
    } else {
        return [self smallPhotoUrl];
    }
}

- (NSURL *)smallPhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *localPath = [[ImageStore sharedImageStore] pathForKey:self.photoKey forSize:ImageStoreSmallSize];

    if (self.photoKey && localPath && [fm fileExistsAtPath:localPath]) {
        return [NSURL fileURLWithPath:localPath];
    } else if (self.smallURL) {
        return [NSURL URLWithString:self.smallURL];
    } else {
        return [self thumbPhotoUrl];
    }
}

- (NSURL *)thumbPhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *localPath = [[ImageStore sharedImageStore] pathForKey:self.photoKey forSize:ImageStoreSquareSize];

    if (self.photoKey && localPath && [fm fileExistsAtPath:localPath]) {
        return [NSURL fileURLWithPath:localPath];
    } else if (self.thumbURL) {
        return [NSURL URLWithString:self.thumbURL];
    } else {
        return nil;
    }
}

- (NSURL *)squarePhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *localPath = [[ImageStore sharedImageStore] pathForKey:self.photoKey forSize:ImageStoreSquareSize];
    
    if (self.photoKey && localPath && [fm fileExistsAtPath:localPath]) {
        return [NSURL fileURLWithPath:localPath];
    } else if (self.squareURL) {
        return [NSURL URLWithString:self.squareURL];
    } else {
        return nil;
    }
}

- (void)willSave {
    [super willSave];
    
    if (!self.uuid && !self.recordID) {
        [self setPrimitiveValue:[[[NSUUID UUID] UUIDString] lowercaseString]
                         forKey:@"uuid"];
    }
}

// should take an error
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

@end
