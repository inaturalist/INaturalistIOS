//
//  ExploreObservationRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreObservationRealm.h"

#import "ExploreCommentRealm.h"
#import "ExploreIdentificationRealm.h"
#import "ExploreUserRealm.h"

@implementation ExploreObservationRealm

- (instancetype)initWithMantleModel:(ExploreObservation *)model {
    if (self = [super init]) {
        
        self.observationId = model.observationId;
        self.speciesGuess = model.speciesGuess;
        self.inatDescription = model.inatDescription;
        self.timeObservedAt = model.timeObservedAt;
        self.observedOn = model.observedOn;
        self.qualityGrade = model.qualityGrade;
        self.identificationsCount = model.identificationsCount;
        self.commentsCount = model.commentsCount;
        self.mappable = model.mappable;
        self.publicPositionalAccuracy = model.publicPositionalAccuracy;
        self.coordinatesObscured = model.coordinatesObscured;
        self.placeGuess = model.placeGuess;
        self.latitude = model.latitude;
        self.longitude = model.longitude;
        self.uuid = model.uuid;
        self.geoprivacy = model.geoprivacy;
        self.captive = model.captive;
        
        self.syncedAt = nil;
        
        if (model.taxon) {
            self.taxon = [[ExploreTaxonRealm alloc] initWithMantleModel:model.taxon];
        }
        
        if (model.user) {
            self.user = [[ExploreUserRealm alloc] initWithMantleModel:model.user];
        }
        
        for (ExploreComment *comment in model.comments) {
            ExploreCommentRealm *ecr = [[ExploreCommentRealm alloc] initWithMantleModel:comment];
            [self.comments addObject:ecr];
        }
    
        for (ExploreIdentification *identification in model.identifications) {
            ExploreIdentificationRealm *eir = [[ExploreIdentificationRealm alloc] initWithMantleModel:identification];
            [self.identifications addObject:eir];
        }
        
        for (ExploreObservationFieldValue *fieldValue in model.observationFieldValues) {
            ExploreObservationFieldValueRealm *eofvr = [[ExploreObservationFieldValueRealm alloc] initWithMantleModel:fieldValue];
            [self.observationFieldValues addObject:eofvr];
        }
        
        for (ExploreObservationPhoto *obsPhoto in model.observationPhotos) {
            ExploreObservationPhotoRealm *eopr = [[ExploreObservationPhotoRealm alloc] initWithMantleModel:obsPhoto];
            [self.observationPhotos addObject:eopr];
        }
        
        for (ExploreFave *fave in model.faves) {
            ExploreFaveRealm *efr = [[ExploreFaveRealm alloc] initWithMantleModel:fave];
            [self.faves addObject:efr];
        }
    }
    
    return self;
}


+ (NSString *)primaryKey {
    return @"uuid";
}

- (NSArray *)sortedObservationPhotos {
    return self.observationPhotos;
}

- (ObsDataQuality)dataQuality {
    if ([self.qualityGrade isEqualToString:@"research"]) {
        return ObsDataQualityResearch;
    } else if ([self.qualityGrade isEqualToString:@"needs_id"]) {
        return ObsDataQualityNeedsID;
    } else {
        // must be casual?
        return ObsDataQualityCasual;
    }
}


- (ExploreTaxonRealm *)exploreTaxonRealm {
    return self.taxon;
}

- (BOOL)hasUnviewedActivityBool {
    // TODO: tbd
    return NO;
}

- (NSString *)iconicTaxonName {
    return self.taxon.iconicTaxonName;
}

- (NSInteger)inatRecordId {
    return self.observationId;
}

- (BOOL)isCaptive {
    return self.captive;
}

- (BOOL)isEditable {
    return YES;
}

+ (NSDateFormatter *)shortDateFormatter
{
    static dispatch_once_t once;
    static NSDateFormatter *shortFormatter;
    dispatch_once(&once, ^{
        shortFormatter = [[NSDateFormatter alloc] init];
        shortFormatter.dateStyle = NSDateFormatterShortStyle;
        shortFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return shortFormatter;
}

- (NSString *)observedOnShortString {
    return [[self.class shortDateFormatter] stringFromDate:self.observedOn];
}

- (NSSet *)projectObservations {
    // TODO: tbd
    return [NSSet set];
}


- (NSString *)sortable {
    
    // TODO: tbd
    return nil;
}


- (NSArray *)sortedActivity {
    NSMutableArray *activity = [NSMutableArray array];
    for (ExploreCommentRealm *comment in self.comments) {
        [activity addObject:comment];
    }
    for (ExploreIdentificationRealm *identification in self.identifications) {
        [activity addObject:identification];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    return [activity sortedArrayUsingDescriptors:@[ sortDescriptor ]];
}


- (NSArray *)sortedFaves {
    
    // TODO: tbd
    return self.faves;
}

- (NSInteger)taxonRecordID {
    return self.taxon.taxonId;
}


- (NSInteger)userID {
    return self.user.userId;
}


- (NSURL *)userThumbUrl {
    return self.user.userIcon;
}


- (NSString *)username {
    return self.user.login;
}


- (CLLocationCoordinate2D)visibleLocation {
    if (CLLocationCoordinate2DIsValid(self.location)) {
        return self.location;
    } else {
        return kCLLocationCoordinate2DInvalid;
    }
}


- (CLLocationAccuracy)visiblePositionalAccuracy {
    // TODO: tbd
    return 0;
}


- (NSArray *)childrenNeedingUpload {
    // TODO: tbd
    return @[];
}

+ (NSArray *)needingUpload {
    // TODO: tbd
    return @[];
}

- (BOOL)needsUpload {
    // TODO: tbd
    return NO;
}

- (NSDictionary *)uploadableRepresentation {
    // TODO: tbd
    return @{};
}

- (NSInteger)activityCount {
    return self.identifications.count + self.comments.count;
}


- (CLLocationCoordinate2D)location {
    if (self.latitude == 0.0) {
        return kCLLocationCoordinate2DInvalid;
    } else {
        return CLLocationCoordinate2DMake(self.latitude, self.longitude);
    }
}

@end
