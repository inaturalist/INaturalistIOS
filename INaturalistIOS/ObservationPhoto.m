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

@synthesize photoSource = _photoSource;
@synthesize index = _index;
@synthesize size = _size;
@synthesize caption = _caption;

- (void)prepareForDeletion
{
    [super prepareForDeletion];
    [[ImageStore sharedImageStore] destroy:self.photoKey];
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
         nil];
    }
    return defaultSerializationMapping;
}

// checks the associated observation for its recordID
- (NSNumber *)observationID
{
    [self willAccessValueForKey:@"observationID"];
    if (!self.primitiveObservationID || [self.primitiveObservationID intValue] == 0) {
        [self setPrimitiveObservationID:self.observation.recordID];
    }
    [self didAccessValueForKey:@"observationID"];
    return [self primitiveObservationID];
}

#pragma mark TTPhoto protocol methods
- (NSString *)URLForVersion:(TTPhotoVersion)version
{
    NSString *url;
    if (self.photoKey) {
        switch (version) {
            case TTPhotoVersionThumbnail:
                url = [[ImageStore sharedImageStore] urlStringForKey:self.photoKey 
                                                             forSize:ImageStoreSquareSize];
                break;
            case TTPhotoVersionSmall:
                url = [[ImageStore sharedImageStore] urlStringForKey:self.photoKey 
                                                             forSize:ImageStoreSmallSize];
                break;
            case TTPhotoVersionMedium:
                url = [[ImageStore sharedImageStore] urlStringForKey:self.photoKey 
                                                             forSize:ImageStoreSmallSize];
                break;
            case TTPhotoVersionLarge:
                url = [[ImageStore sharedImageStore] urlStringForKey:self.photoKey 
                                                             forSize:ImageStoreLargeSize];
                break;
            default:
                url = nil;
                break;
        }
    } else {
        switch (version) {
            case TTPhotoVersionThumbnail:
                url = self.squareURL;
                break;
            case TTPhotoVersionSmall:
                url = self.smallURL;
                break;
            case TTPhotoVersionMedium:
                url = self.mediumURL;
                break;
            case TTPhotoVersionLarge:
                url = self.largeURL;
                break;
            default:
                url = nil;
                break;
        }
    }
    return url;
}

- (CGSize)size
{
    // since size is a struct, it sort of already has all its "attributes" in place, 
    // but they have been initialized to zero, so this is the equivalent of a null check
    if (_size.width == 0) {
        UIImage *img = [[ImageStore sharedImageStore] find:self.photoKey forSize:ImageStoreLargeSize];
        if (img) {
            [self setSize:img.size];
        } else {
            // it'll just figure it out when the image loads
        }
    }
    return _size;

}

- (NSString *)caption
{
    if (!_caption) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"hh:mm aaa MMM d, yyyy"];
        _caption = [NSString stringWithFormat:@"Added at %@", [fmt stringFromDate:self.localCreatedAt]];
    }
    return _caption;
}

- (NSArray *)remoteOnlyAttributes
{
    return [NSArray arrayWithObjects:@"licenseCode", nil];
}

@end
