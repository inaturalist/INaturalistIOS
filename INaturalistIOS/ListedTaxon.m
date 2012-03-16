//
//  ListedTaxon.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ListedTaxon.h"
#import "List.h"

static RKManagedObjectMapping *defaultMapping = nil;
//static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation ListedTaxon

@dynamic recordID;
@dynamic listID;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;
@dynamic taxonID;
@dynamic firstObservationID;
@dynamic lastObservationID;
@dynamic occurrenceStatus;
@dynamic establishmentMeans;
@dynamic taxonName;
@dynamic taxonDefaultName;
@dynamic desc;
@dynamic ancestry;
@dynamic placeID;
@dynamic list;
@dynamic photoURL;
@dynamic iconicTaxonName;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
         @"description", @"desc",
         @"place_id", @"placeID",
         @"taxon_id", @"taxonID",
         @"list_id", @"listID",
         @"taxon_ancestor_ids", @"ancestry",
         @"establishment_means", @"establishmentMeans",
         @"first_observation_id", @"firstObservationID",
         @"last_observation_id", @"lastObservationID",
         @"occurrence_status", @"occurrenceStatus",
         @"taxon.default_name.name", @"taxonDefaultName",
         @"taxon.name", @"taxonName",
         @"taxon.iconic_taxon_name", @"iconicTaxonName",
         @"taxon.photo_url", @"photoURL",
         nil];
        [defaultMapping connectRelationship:@"list" withObjectForPrimaryKeyAttribute:@"listID"];
        [defaultMapping mapRelationship:@"list" withMapping:[List mapping]];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

@end
