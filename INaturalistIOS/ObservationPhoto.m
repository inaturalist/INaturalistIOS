//
//  ObservationPhoto.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationPhoto.h"
#import "Observation.h"
#import "ImageStore.h"

@implementation ObservationPhoto

@dynamic createdAt;
@dynamic largeURL;
@dynamic license_code;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic mediumURL;
@dynamic nativePageURL;
@dynamic nativeRealName;
@dynamic nativeUsername;
@dynamic observationID;
@dynamic originalURL;
@dynamic position;
@dynamic recordID;
@dynamic smallURL;
@dynamic squareURL;
@dynamic syncedAt;
@dynamic thumbURL;
@dynamic updatedAt;
@dynamic observation;
@dynamic photoKey;

- (void)prepareForDeletion
{
    [super prepareForDeletion];
    [[ImageStore sharedImageStore] destroy:self.photoKey];
}

@end
