//
//  Identification.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/5/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "Identification.h"
#import "Observation.h"
#import "Taxon.h"
#import "User.h"
#import "TaxonPhoto.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKObjectMapping *defaultSerializationMapping = nil;

@implementation Identification

@dynamic recordID;
@dynamic body;
@dynamic createdAt;
@dynamic current;
@dynamic updatedAt;
@dynamic observationID;
@dynamic taxonChangeID;
@dynamic taxonID;
@dynamic userID;
@dynamic observation;
@dynamic taxon;
@dynamic user;

- (NSInteger)userId {
    return self.userID.integerValue;
}

- (NSDate *)date {
    return self.createdAt;
}

- (NSString *)userName {
    return self.user.login;
}

- (NSURL *)userIconUrl {
    return [NSURL URLWithString:self.user.userIconURL];
}

- (NSString *)taxonCommonName {
    return self.taxon.defaultName;
}

- (NSString *)taxonScientificName {
    return self.taxon.name;
}

- (NSString *)taxonIconicName {
	return self.taxon.iconicTaxonName;
}

- (NSInteger)taxonId {
    return self.taxon.recordID.integerValue;
}

- (NSInteger)taxonRankLevel {
    return self.taxon.rankLevel.integerValue;
}

- (NSString *)taxonRank {
    return self.taxon.rank;
}

- (NSURL *)taxonIconUrl {
    if (self.taxon.taxonPhotos.count > 0 ) {
        TaxonPhoto *tp = self.taxon.taxonPhotos.firstObject;
        return [NSURL URLWithString:tp.squareURL];
    } else {
        return nil;
    }
}

- (BOOL)isCurrent {
    return self.current.boolValue;
}


+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[Identification class]
                                            inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"body", @"body",
		 @"created_at", @"createdAt",
		 @"updated_at", @"updatedAt",
         @"current", @"current",
         @"observation_id", @"observationID",
         @"taxon_change_id", @"taxonChangeID",
         @"taxon_id", @"taxonID",
         @"user_id", @"userID",
         nil];
        [defaultMapping mapKeyPath:@"taxon"
                    toRelationship:@"taxon"
                       withMapping:[Taxon mapping]
                         serialize:YES];
		[defaultMapping mapKeyPath:@"user"
                    toRelationship:@"user"
                       withMapping:[User mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [[RKManagedObjectMapping mappingForClass:[Identification class]
                                                          inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]] inverseMapping];
        [defaultSerializationMapping mapKeyPathsToAttributes:
         @"observationID", @"identification[observation_id]",
         @"taxonID", @"identification[taxon_id]",
		 @"body", @"identification[body]",
         nil];
    }
    return defaultSerializationMapping;
}

- (NSString *)createdAtPrettyString
{
    if (!self.createdAt) return @"Unknown";
    return [Identification.prettyDateFormatter stringFromDate:self.createdAt];
}

- (NSString *)createdAtShortString
{
    if (!self.createdAt) return @"Unknown";
    return [Identification.shortDateFormatter stringFromDate:self.createdAt];
}

@end