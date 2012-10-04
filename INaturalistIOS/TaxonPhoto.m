//
//  TaxonPhoto.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/21/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "TaxonPhoto.h"
#import "Taxon.h"

static RKManagedObjectMapping *defaultMapping = nil;

@implementation TaxonPhoto

@dynamic recordID;
@dynamic updatedAt;
@dynamic createdAt;
@dynamic localUpdatedAt;
@dynamic localCreatedAt;
@dynamic syncedAt;
@dynamic position;
@dynamic taxonID;
@dynamic nativePhotoID;
@dynamic squareURL;
@dynamic thumbURL;
@dynamic smallURL;
@dynamic mediumURL;
@dynamic largeURL;
@dynamic nativePageURL;
@dynamic nativeUsername;
@dynamic nativeRealname;
@dynamic licenseCode;
@dynamic attribution;
@dynamic taxon;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:self.class inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"taxon_id", @"taxonID",
         @"createdAt", @"createdAt",
         @"updatedAt", @"updatedAt",
         @"position", @"position",
         @"photo.large_url", @"largeURL",
         @"photo.medium_url", @"mediumURL",
         @"photo.small_url", @"smallURL",
         @"photo.thumb_url", @"thumbURL",
         @"photo.square_url", @"squareURL",
         @"photo.native_page_url", @"nativePageURL",
         @"photo.native_photo_id", @"nativePhotoID",
         @"photo.native_username", @"nativeUsername",
         @"photo.native_realname", @"nativeRealname",
         @"photo.license_code", @"licenseCode",
         @"photo.attribution", @"attribution",
         nil];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

@end
