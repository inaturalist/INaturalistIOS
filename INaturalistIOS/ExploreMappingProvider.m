//
//  ExploreMappingProvider.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreMappingProvider.h"
#import "ExploreObservation.h"
#import "ExploreObservationPhoto.h"
#import "ExploreLocation.h"
#import "ExploreProject.h"
#import "ExploreIdentification.h"
#import "ExploreComment.h"
#import "ExploreTaxon.h"
#import "ExplorePerson.h"
#import "IdentifierCount.h"
#import "ObserverCount.h"
#import "SpeciesCount.h"
#import "Taxon.h"
#import "ExploreFave.h"

@implementation ExploreMappingProvider

+ (RKObjectMapping *)personMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExplorePerson class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"personId"];
    [mapping mapKeyPath:@"login" toAttribute:@"login"];
    [mapping mapKeyPath:@"name" toAttribute:@"name"];
    [mapping mapKeyPath:@"user_icon" toAttribute:@"userIcon"];

    return mapping;
}

+ (RKObjectMapping *)nodeTaxonMapping {
    RKObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[Taxon class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"recordID"];
    [mapping mapKeyPath:@"name" toAttribute:@"name"];
    [mapping mapKeyPath:@"rank_level" toAttribute:@"rankLevel"];
    [mapping mapKeyPath:@"rank" toAttribute:@"rank"];
    [mapping mapKeyPath:@"preferred_common_name" toAttribute:@"defaultName"];
    
    return mapping;
}

+ (RKObjectMapping *)taxonMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreTaxon class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"taxonId"];
    [mapping mapKeyPath:@"default_photo.medium_url" toAttribute:@"taxonPhotoUrl"];
    [mapping mapKeyPath:@"wikipedia_summary" toAttribute:@"taxonWebContent"];
    [mapping mapKeyPath:@"preferred_common_name" toAttribute:@"taxonCommonName"];
    
    return mapping;
}


+ (RKObjectMapping *)identificationMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreIdentification class]];

    [mapping mapKeyPath:@"id" toAttribute:@"identificationId"];
    [mapping mapKeyPath:@"taxon.name" toAttribute:@"identificationScientificName"];
    [mapping mapKeyPath:@"current" toAttribute:@"identificationIsCurrent"];
    [mapping mapKeyPath:@"taxon.preferred_common_name" toAttribute:@"identificationCommonName"];
    [mapping mapKeyPath:@"taxon.default_photo.square_url" toAttribute:@"identificationPhotoUrlString"];
    [mapping mapKeyPath:@"body" toAttribute:@"identificationBody"];
    [mapping mapKeyPath:@"taxon.id" toAttribute:@"identificationTaxonId"];
    [mapping mapKeyPath:@"taxon.rank" toAttribute:@"identificationTaxonRank"];
    [mapping mapKeyPath:@"taxon.rank_level" toAttribute:@"identificationTaxonRankLevel"];
    [mapping mapKeyPath:@"taxon.iconic_taxon_name" toAttribute:@"identificationIconicTaxonName"];
    [mapping mapKeyPath:@"user.id" toAttribute:@"identifierId"];
    [mapping mapKeyPath:@"user.login" toAttribute:@"identifierName"];
    [mapping mapKeyPath:@"user.icon_url" toAttribute:@"identifierIconUrl"];
    [mapping mapKeyPath:@"created_at" toAttribute:@"identifiedDate"];

    return mapping;
}

+ (RKObjectMapping *)commentMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreComment class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"commentId"];
    [mapping mapKeyPath:@"body" toAttribute:@"commentText"];
    [mapping mapKeyPath:@"user.login" toAttribute:@"commenterName"];
    [mapping mapKeyPath:@"user.id" toAttribute:@"commenterId"];
    [mapping mapKeyPath:@"created_at" toAttribute:@"commentedDate"];
    [mapping mapKeyPath:@"user.icon_url" toAttribute:@"commenterIconUrl"];

    return mapping;
}

+ (RKObjectMapping *)faveMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreFave class]];

    [mapping mapKeyPath:@"user.login" toAttribute:@"faverName"];
    [mapping mapKeyPath:@"user.id" toAttribute:@"faverId"];
    [mapping mapKeyPath:@"created_at" toAttribute:@"faveDate"];
    [mapping mapKeyPath:@"user.icon_url" toAttribute:@"faverIconUrl"];
    
    return mapping;
}


+ (RKObjectMapping *)observationMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreObservation class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"observationId"];
    
    [mapping mapKeyPath:@"longitude" toAttribute:@"longitude"];
    [mapping mapKeyPath:@"latitude" toAttribute:@"latitude"];
    [mapping mapKeyPath:@"location" toAttribute:@"locationCoordinateString"];
    
    [mapping mapKeyPath:@"description" toAttribute:@"inatDescription"];
    
    [mapping mapKeyPath:@"species_guess" toAttribute:@"speciesGuess"];
    [mapping mapKeyPath:@"taxon.iconic_taxon_name" toAttribute:@"iconicTaxonName"];
    [mapping mapKeyPath:@"taxon.name" toAttribute:@"taxonName"];
    [mapping mapKeyPath:@"taxon.id" toAttribute:@"taxonId"];
    [mapping mapKeyPath:@"taxon.rank" toAttribute:@"taxonRank"];
    [mapping mapKeyPath:@"taxon.common_name.name" toAttribute:@"commonName"];
    [mapping mapKeyPath:@"time_observed_at_utc" toAttribute:@"timeObservedAt"];
    [mapping mapKeyPath:@"observed_on" toAttribute:@"observedOn"];
    [mapping mapKeyPath:@"quality_grade" toAttribute:@"qualityGrade"];
    [mapping mapKeyPath:@"id_please" toAttribute:@"idPlease"];
    
    [mapping mapKeyPath:@"user.id" toAttribute:@"observerId"];
    [mapping mapKeyPath:@"user.login" toAttribute:@"observerName"];
    [mapping mapKeyPath:@"user.icon_url" toAttribute:@"observerIconUrl"];

    [mapping mapKeyPath:@"identifications_count" toAttribute:@"identificationsCount"];
    [mapping mapKeyPath:@"comments_count" toAttribute:@"commentsCount"];
    [mapping mapKeyPath:@"mappable" toAttribute:@"mappable"];
    [mapping mapKeyPath:@"public_positional_accuracy" toAttribute:@"publicPositionalAccuracy"];
    [mapping mapKeyPath:@"coordinates_obscured" toAttribute:@"coordinatesObscured"];
    [mapping mapKeyPath:@"place_guess" toAttribute:@"placeGuess"];
    
    [mapping mapKeyPath:@"photos" toRelationship:@"observationPhotos" withMapping:[self observationPhotoMapping]];
    [mapping mapKeyPath:@"comments" toRelationship:@"comments" withMapping:[self commentMapping]];
    [mapping mapKeyPath:@"identifications" toRelationship:@"identifications" withMapping:[self identificationMapping]];
    [mapping mapKeyPath:@"faves" toRelationship:@"faves" withMapping:[self faveMapping]];
    
    [mapping mapKeyPath:@"taxon" toRelationship:@"taxon" withMapping:[self nodeTaxonMapping]];
    
    return mapping;
}

+ (RKObjectMapping *)observationPhotoMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreObservationPhoto class]];
    
    [mapping mapKeyPath:@"medium_url" toAttribute:@"mediumURL"];
    [mapping mapKeyPath:@"square_url" toAttribute:@"squareURL"];
    [mapping mapKeyPath:@"thumb_url" toAttribute:@"thumbURL"];
    [mapping mapKeyPath:@"large_url" toAttribute:@"largeURL"];
    [mapping mapKeyPath:@"small_url" toAttribute:@"smallURL"];
    [mapping mapKeyPath:@"url" toAttribute:@"url"];
    
    return mapping;
}

+ (RKObjectMapping *)locationMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreLocation class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"locationId"];
    [mapping mapKeyPath:@"place_type" toAttribute:@"type"];
    [mapping mapKeyPath:@"display_name" toAttribute:@"name"];
    [mapping mapKeyPath:@"longitude" toAttribute:@"longitude"];
    [mapping mapKeyPath:@"latitude" toAttribute:@"latitude"];
    [mapping mapKeyPath:@"admin_level" toAttribute:@"adminLevel"];
    [mapping mapKeyPath:@"place_type_name" toAttribute:@"placeTypeName"];

    return mapping;
}

+ (RKObjectMapping *)projectMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreProject class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"projectId"];
    [mapping mapKeyPath:@"title" toAttribute:@"title"];
    [mapping mapKeyPath:@"place_id" toAttribute:@"locationId"];
    [mapping mapKeyPath:@"longitude" toAttribute:@"longitude"];
    [mapping mapKeyPath:@"latitude" toAttribute:@"latitude"];
    [mapping mapKeyPath:@"observed_taxa_count" toAttribute:@"observedTaxaCount"];
    [mapping mapKeyPath:@"icon_url" toAttribute:@"iconUrl"];


    return mapping;
}

+ (RKObjectMapping *)speciesCountMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[SpeciesCount class]];
    
    [mapping mapKeyPath:@"count" toAttribute:@"speciesCount"];
    [mapping mapKeyPath:@"taxon.preferred_common_name" toAttribute:@"commonName"];
    [mapping mapKeyPath:@"taxon.name" toAttribute:@"scientificName"];
    [mapping mapKeyPath:@"taxon.id" toAttribute:@"taxonId"];
    [mapping mapKeyPath:@"taxon.default_photo.square_url" toAttribute:@"squarePhotoUrl"];
    [mapping mapKeyPath:@"taxon.rank_level" toAttribute:@"speciesRankLevel"];
    [mapping mapKeyPath:@"taxon.rank" toAttribute:@"speciesRank"];

    return mapping;
}
+ (RKObjectMapping *)observerCountMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ObserverCount class]];
    
    [mapping mapKeyPath:@"observation_count" toAttribute:@"observationCount"];
    [mapping mapKeyPath:@"species_count" toAttribute:@"speciesCount"];
    [mapping mapKeyPath:@"user.id" toAttribute:@"observerId"];
    [mapping mapKeyPath:@"user.login" toAttribute:@"observerName"];
    [mapping mapKeyPath:@"user.icon_url" toAttribute:@"observerIconUrl"];

    return mapping;

}
+ (RKObjectMapping *)identifierCountMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[IdentifierCount class]];
    
    [mapping mapKeyPath:@"count" toAttribute:@"identificationCount"];
    [mapping mapKeyPath:@"user.id" toAttribute:@"identifierId"];
    [mapping mapKeyPath:@"user.login" toAttribute:@"identifierName"];
    [mapping mapKeyPath:@"user.icon_url" toAttribute:@"identifierIconUrl"];


    return mapping;
}



@end
