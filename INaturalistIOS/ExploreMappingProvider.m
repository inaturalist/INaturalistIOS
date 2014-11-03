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

@implementation ExploreMappingProvider

+ (RKObjectMapping *)personMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExplorePerson class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"personId"];
    [mapping mapKeyPath:@"login" toAttribute:@"login"];
    [mapping mapKeyPath:@"name" toAttribute:@"name"];

    return mapping;
}

+ (RKObjectMapping *)taxonMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreTaxon class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"taxonId"];
    [mapping mapKeyPath:@"default_photo.medium_url" toAttribute:@"taxonPhotoUrl"];
    [mapping mapKeyPath:@"wikipedia_summary" toAttribute:@"taxonWebContent"];
    
    return mapping;
}


+ (RKObjectMapping *)identificationMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreIdentification class]];

    [mapping mapKeyPath:@"id" toAttribute:@"identificationId"];
    [mapping mapKeyPath:@"taxon.name" toAttribute:@"identificationScientificName"];
    [mapping mapKeyPath:@"taxon.common_name.name" toAttribute:@"identificationCommonName"];
    [mapping mapKeyPath:@"taxon.photo_url" toAttribute:@"identificationPhotoUrlString"];
    [mapping mapKeyPath:@"body" toAttribute:@"identificationBody"];
    [mapping mapKeyPath:@"taxon_id" toAttribute:@"identificationTaxonId"];
    [mapping mapKeyPath:@"taxon.rank" toAttribute:@"identificationTaxonRank"];
    [mapping mapKeyPath:@"taxon.iconic_taxon_name" toAttribute:@"identificationIconicTaxonName"];
    [mapping mapKeyPath:@"user.id" toAttribute:@"identifierId"];
    [mapping mapKeyPath:@"user.login" toAttribute:@"identifierName"];
    [mapping mapKeyPath:@"user.user_icon_url" toAttribute:@"identifierIconUrl"];
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
    [mapping mapKeyPath:@"user.user_icon_url" toAttribute:@"commenterIconUrl"];

    return mapping;
}

+ (RKObjectMapping *)observationMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreObservation class]];
    
    [mapping mapKeyPath:@"id" toAttribute:@"observationId"];
    [mapping mapKeyPath:@"longitude" toAttribute:@"longitude"];
    [mapping mapKeyPath:@"latitude" toAttribute:@"latitude"];
    [mapping mapKeyPath:@"species_guess" toAttribute:@"speciesGuess"];
    [mapping mapKeyPath:@"user_login" toAttribute:@"observerName"];
    [mapping mapKeyPath:@"iconic_taxon_name" toAttribute:@"iconicTaxonName"];
    [mapping mapKeyPath:@"taxon.name" toAttribute:@"taxonName"];
    [mapping mapKeyPath:@"taxon.id" toAttribute:@"taxonId"];
    [mapping mapKeyPath:@"taxon.rank" toAttribute:@"taxonRank"];
    [mapping mapKeyPath:@"taxon.common_name.name" toAttribute:@"commonName"];
    [mapping mapKeyPath:@"time_observed_at_utc" toAttribute:@"timeObservedAt"];
    [mapping mapKeyPath:@"observed_on" toAttribute:@"observedOn"];
    [mapping mapKeyPath:@"quality_grade" toAttribute:@"qualityGrade"];
    [mapping mapKeyPath:@"id_please" toAttribute:@"idPlease"];
    [mapping mapKeyPath:@"user_id" toAttribute:@"observerId"];
    [mapping mapKeyPath:@"identifications_count" toAttribute:@"identificationsCount"];
    [mapping mapKeyPath:@"comments_count" toAttribute:@"commentsCount"];
    [mapping mapKeyPath:@"mappable" toAttribute:@"mappable"];
    [mapping mapKeyPath:@"public_positional_accuracy" toAttribute:@"publicPositionalAccuracy"];
    [mapping mapKeyPath:@"coordinates_obscured" toAttribute:@"coordinatesObscured"];
    [mapping mapKeyPath:@"place_guess" toAttribute:@"placeGuess"];
    
    [mapping mapKeyPath:@"photos" toRelationship:@"observationPhotos" withMapping:[self observationPhotoMapping]];
    [mapping mapKeyPath:@"comments" toRelationship:@"comments" withMapping:[self commentMapping]];
    [mapping mapKeyPath:@"identifications" toRelationship:@"identifications" withMapping:[self identificationMapping]];
    
    return mapping;
}

+ (RKObjectMapping *)observationPhotoMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ExploreObservationPhoto class]];
    
    [mapping mapKeyPath:@"medium_url" toAttribute:@"mediumURL"];
    [mapping mapKeyPath:@"square_url" toAttribute:@"squareURL"];
    [mapping mapKeyPath:@"thumb_url" toAttribute:@"thumbURL"];
    [mapping mapKeyPath:@"large_url" toAttribute:@"largeURL"];
    [mapping mapKeyPath:@"small_url" toAttribute:@"smallURL"];
    
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


@end
