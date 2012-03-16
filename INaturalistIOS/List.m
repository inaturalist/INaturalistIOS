//
//  List.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "List.h"
#import "ListedTaxon.h"

static RKManagedObjectMapping *defaultMapping = nil;
//static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation List

@dynamic recordID;
@dynamic title;
@dynamic desc;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic syncedAt;
@dynamic comprehensive;
@dynamic type;
@dynamic taxonID;
@dynamic placeID;
@dynamic projectID;
@dynamic listedTaxa;
@dynamic project;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
         @"title", @"title",
         @"description", @"desc",
         @"comprehensive", @"comprehensive",
         @"place_id", @"placeID",
         @"project_id", @"projectID",
         @"taxon_id", @"taxonID",
         @"type", @"type",
         nil];
        [defaultMapping mapKeyPath:@"listed_taxa" 
                    toRelationship:@"listedTaxa" 
                       withMapping:[ListedTaxon mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

@end
