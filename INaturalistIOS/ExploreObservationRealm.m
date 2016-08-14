//
//  ExploreObservationRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreObservationRealm.h"

@implementation ExploreObservationRealm

- (instancetype)initWithMantleModel:(ExploreObservation *)model  {
    if (self = [super init]) {
    	self.geoprivacy = model.geoprivacy;
    	self.qualityGrade = model.qualityGrade;
        self.uuid  = model.uuid;
        self.observationId = model.observationId;
        self.speciesGuess = model.speciesGuess;
        self.inatDescription = model.inatDescription;
        self.timeObservedAt = model.timeObservedAt;
        self.createdAt = model.createdAt;
        self.observedOn = model.observedOn;
        self.qualityGrade = model.qualityGrade;
        self.idPlease = model.idPlease;
        self.identificationsCount = model.identificationsCount;
        self.commentsCount = model.commentsCount;
        self.favesCount = model.favesCount;
        self.mappable = model.mappable;
        self.publicPositionalAccuracy = model.publicPositionalAccuracy;
        self.coordinatesObscured = model.coordinatesObscured;
        self.placeGuess = model.placeGuess;
        self.latitude = model.latitude;
        self.longitude = model.longitude;
        self.privateLatitude = model.privateLatitude;
        self.privateLongitude = model.privateLongitude;
        self.hasUnviewedActivity = NO;
        self.validationErrorMsg = nil;
        
        if (model.taxon) {
            self.taxon = [[ExploreTaxonRealm alloc] initWithMantleModel:model.taxon];
        }
        self.user = [[ExploreUserRealm alloc] initWithMantleModel:model.user];
        
        for (ExploreObservationPhoto *op in model.observationPhotos) {
        	ExploreObservationPhotoRealm *eopr = [[ExploreObservationPhotoRealm alloc] initWithMantleModel:op];
        	[self.observationPhotos addObject:eopr];
        }
        for (ExploreIdentification *ei in model.identifications) {
        	ExploreIdentificationRealm *eir = [[ExploreIdentificationRealm alloc] initWithMantleModel:ei];
        	[self.identifications addObject:eir];
        }
        for (ExploreComment *ec in model.comments) {
        	ExploreCommentRealm *ecr = [[ExploreCommentRealm alloc] initWithMantleModel:ec];
        	[self.comments addObject:ecr];
        }
        for (ExploreFave *ef in model.faves) {
        	ExploreFaveRealm *efr = [[ExploreFaveRealm alloc] initWithMantleModel:ef];
        	[self.faves addObject:efr];
        }
    }
    
    return self;
}

+ (NSString *)primaryKey {
    return @"observationId";
}

- (NSString *)iconicTaxonName {
    return self.taxon ? self.taxon.iconicTaxonName : @"";
}

- (NSArray *)sortedActivity {
    NSMutableArray *activity = [NSMutableArray array];
    for (ExploreCommentRealm *ecr in self.comments) {
        [activity addObject:ecr];
    }
    for (ExploreIdentificationRealm *eir in self.identifications) {
        [activity addObject:eir];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    NSArray *sortedActivity = [activity sortedArrayUsingDescriptors:@[ sortDescriptor ]];
    
    return sortedActivity;
}

- (NSInteger)activityCount {
    return self.identificationsCount + self.commentsCount;
}

- (BOOL)needsUpload {
    return NO;
}

- (NSString *)username {
    return self.user.login;
}

- (BOOL)isEditable {
    return YES;
}

- (NSSet *)projectObservations {
    return [NSSet set];
}

- (NSInteger)inatRecordId {
    return self.observationId;
}

- (NSURL *)userThumbUrl {
    return self.user.userIcon;
}

- (NSString *)observedOnShortString {
    return @"Now";
}

- (NSArray *)sortedObservationPhotos {
    return self.observationPhotos;
}

- (BOOL)isCaptive {
    return NO;
}

- (CLLocationCoordinate2D)location {
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

- (CLLocationCoordinate2D)privateLocation {
    return CLLocationCoordinate2DMake(self.privateLatitude, self.privateLongitude);
}


- (CLLocationCoordinate2D)visibleLocation {
    if (CLLocationCoordinate2DIsValid(self.privateLocation) && !(self.privateLocation.latitude == 0)) {
        return self.privateLocation;
    } else if (CLLocationCoordinate2DIsValid(self.location) && !(self.location.latitude == 0)) {
        return self.location;
    } else {
        // invalid location
        return CLLocationCoordinate2DMake(-19999.0,-19999.0);
    }
}

- (CLLocationDistance)visiblePositionalAccuracy {
    return self.publicPositionalAccuracy;
}


@end
