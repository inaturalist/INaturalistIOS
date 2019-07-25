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
        self.positionalAccuracy = model.positionalAccuracy;
        self.coordinatesObscured = model.coordinatesObscured;
        self.placeGuess = model.placeGuess;
        self.latitude = model.latitude;
        self.longitude = model.longitude;
        self.uuid = model.uuid;
        self.geoprivacy = model.geoprivacy;
        self.captive = model.captive;
        self.updatedAt = model.updatedAt;
        self.syncedAt = model.syncedAt;
        self.createdAt = model.createdAt;
        
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
        
        for (ExploreProjectObservation *po in model.projectObservations) {
            ExploreProjectObservationRealm *epor = [[ExploreProjectObservationRealm alloc] initWithMantleModel:po];
            [self.projectObservations addObject:epor];
        }
        
        self.hasUnviewedActivityBool = NO;
    }
    
    return self;
}


+ (NSString *)primaryKey {
    return @"uuid";
}

- (NSArray *)sortedObservationPhotos {
    RLMSortDescriptor *positionSort = [RLMSortDescriptor sortDescriptorWithKeyPath:@"position" ascending:YES];
    return [self.observationPhotos sortedResultsUsingDescriptors:@[ positionSort ]];
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

+ (NSDateFormatter *)jsDateFormatter {
    static dispatch_once_t once;
    static NSDateFormatter *jsFormatter;
    dispatch_once(&once, ^{
        jsFormatter = [[NSDateFormatter alloc] init];
        jsFormatter.timeZone = [NSTimeZone localTimeZone];
        jsFormatter.dateFormat = @"EEE MMM dd yyyy HH:mm:ss 'GMT'Z (zzz)";
        
        // per #128 and https://groups.google.com/d/topic/inaturalist/8tE0QTT_kzc/discussion
        // the server doesn't want the observed_on field to be localized
        jsFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en-US"];
    });
    return jsFormatter;
}


- (NSString *)observedOnShortString {
    return [[self.class shortDateFormatter] stringFromDate:self.observedOn];
}

- (NSArray *)projectIds {
    NSMutableArray *projectIds = [NSMutableArray arrayWithCapacity:self.projectObservations.count];
    for (ExploreProjectObservationRealm *po in self.projectObservations) {
        [projectIds addObject:@(po.projectId)];
    }
    return [NSArray arrayWithArray:projectIds];
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
    if (self.coordinatesObscured) {
        return self.publicPositionalAccuracy;
    } else {
        return self.positionalAccuracy;
    }
}


- (NSArray *)childrenNeedingUpload {
    NSMutableArray *childrenNeedingUpload = [NSMutableArray array];
    for (ExploreObservationPhotoRealm *photo in self.observationPhotos) {
        if ([photo needsUpload]) {
            [childrenNeedingUpload addObject:photo];
        }
    }
    
    // TODO: add ovfs, pos
    
    return childrenNeedingUpload;
}

+ (NSArray *)needingUpload {
    NSMutableSet *needingUpload = [NSMutableSet set];
    
    // all observations that need sync themselves are upload candidates
    for (ExploreObservationRealm *obs in [self needingSync]) {
        [needingUpload addObject:obs];
    }
    
    /*
    // also, all observations whose uploadable children need sync
    for (ObservationPhoto *op in [ObservationPhoto needingSync]) {
        if (op.observation) {
            [needingUpload addObject:op.observation];
        }
    }
    
    for (ObservationFieldValue *ofv in [ObservationFieldValue needingSync]) {
        if (ofv.observation) {
            [needingUpload addObject:ofv.observation];
        }
    }
    
    for (ProjectObservation *po in [ProjectObservation needingSync]) {
        if (po.observation) {
            [needingUpload addObject:po.observation];
        }
    }
     */
    
    /*
    return [[needingUpload allObjects] sortedArrayUsingComparator:^NSComparisonResult(INatModel *o1, INatModel *o2) {
        return [o1.localCreatedAt compare:o2.localCreatedAt];
    }];
     */
    return [needingUpload allObjects];
}

- (BOOL)needsUpload {
    // needs upload if this obs needs sync
    if (self.needsSync) { return YES; }
    return NO;
}

+ (RLMResults *)needingSync {
    NSPredicate *syncPredicate = [NSPredicate predicateWithFormat:@"syncedAt == nil OR syncedAt < updatedAt"];
    return [[self class] objectsWithPredicate:syncPredicate];
}

- (BOOL)needsSync {
    return self.syncedAt == nil || [self.syncedAt timeIntervalSinceDate:self.updatedAt] < 0;
}

- (NSDictionary *)uploadableRepresentation {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];

    // mappings for objects
    NSDictionary *objectMappings = @{
                              @"speciesGuess": @"species_guess",
                              @"inatDescription": @"description",
                              @"observedOnString": @"observed_on_string",
                              @"placeGuess": @"place_guess",
                              @"geoprivacy": @"geoprivacy",
                              @"uuid": @"uuid",
                              };
    
    // map the objects
    for (NSString *key in objectMappings) {
        if ([self valueForKey:key]) {
            NSString *mappedName = objectMappings[key];
            mutableParams[mappedName] = [self valueForKey:key];
        }
    }
    
    // handle taxon id separately
    if (self.taxon) {
        mutableParams[@"taxon_id"] = @(self.taxon.taxonId);
    }
    
    // handle location separately
    if (CLLocationCoordinate2DIsValid(self.location)) {
        mutableParams[@"latitude"] = @(self.latitude);
        mutableParams[@"longitude"] = @(self.longitude);
        if (self.positionalAccuracy != 0) {
            mutableParams[@"positional_accuracy"] = @(self.positionalAccuracy);
        }
    }
    
    // handle bools separately
    NSDictionary *boolMappings = @{
                                   @"captive": @"captive_flag",
                                   // TBD: realm
                                   // @"ownersIdentificationFromVision": @"owners_identification_from_vision",
                                   };
    // map the bools
    for (NSString *key in boolMappings) {
        NSString *mappedName = boolMappings[key];
        mutableParams[mappedName] = [[self valueForKey:key] boolValue] ? @"YES" : @"NO";
    }
    
    // return an immutable copy
    // ignore_photos is required to avoid clobbering obs photos
    // when updating an observation via the node endpoint
    return @{
             @"observation": [NSDictionary dictionaryWithDictionary:mutableParams],
             @"ignore_photos": @"YES"
             };
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

- (NSString *)observedOnString {
    return [[[self class] jsDateFormatter] stringFromDate:self.timeObservedAt];
}

+ (NSString *)endpointName {
    return @"observations";
}

@end
