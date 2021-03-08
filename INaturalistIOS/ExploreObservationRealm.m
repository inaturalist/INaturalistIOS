//
//  ExploreObservationRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/31/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreObservationRealm.h"
#import "ExploreDeletedRecord.h"

@implementation ExploreObservationRealm

+ (NSDictionary *)valueForMantleModel:(ExploreObservation *)mtlModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    value[@"observationId"] = @(mtlModel.observationId);
    
    if (mtlModel.uuid) { value[@"uuid"] = mtlModel.uuid; }
    if (mtlModel.speciesGuess) { value[@"speciesGuess"] = mtlModel.speciesGuess; }
    if (mtlModel.taxon) {
        value[@"taxon"] = [ExploreTaxonRealm valueForMantleModel:mtlModel.taxon];
    }
    if (mtlModel.user) {
        value[@"user"] = [ExploreUserRealm valueForMantleModel:mtlModel.user];
    }
    
    if (mtlModel.inatDescription) { value[@"inatDescription"] = mtlModel.inatDescription; }
    if (mtlModel.timeObserved) { value[@"timeObserved"] = mtlModel.timeObserved; }
    if (mtlModel.timeCreated) { value[@"timeCreated"] = mtlModel.timeCreated; }

    value[@"dataQuality"] = @(mtlModel.dataQuality);
    
    value[@"latitude"] = @(mtlModel.latitude);
    value[@"longitude"] = @(mtlModel.longitude);
    value[@"privateLatitude"] = @(mtlModel.privateLocation.latitude);
    value[@"privateLongitude"] = @(mtlModel.privateLocation.longitude);

    value[@"privatePositionalAccuracy"] = @(mtlModel.privatePositionalAccuracy);
    value[@"publicPositionalAccuracy"] = @(mtlModel.publicPositionalAccuracy);
    
    if (mtlModel.placeGuess) { value[@"placeGuess"] = mtlModel.placeGuess; }
    
    value[@"coordinatesObscured"] = @(mtlModel.coordinatesObscured);
    
    value[@"captive"] = @(mtlModel.captive);
    value[@"geoprivacy"] = mtlModel.geoprivacy;
    value[@"ownersIdentificationFromVision"] = @(mtlModel.ownersIdentificationFromVision);
        
    if (mtlModel.observationPhotos) {
        NSMutableArray *eoprs = [NSMutableArray array];
        for (ExploreObservationPhoto *eop in mtlModel.observationPhotos) {
            [eoprs addObject:[ExploreObservationPhotoRealm valueForMantleModel:eop]];
        }
        value[@"observationPhotos"] = [NSArray arrayWithArray:eoprs];
    }
    
    if (mtlModel.observationSounds) {
        NSMutableArray *soundsForRealm = [NSMutableArray array];
        for (ExploreObservationSound *mtlSound in mtlModel.observationSounds) {
            [soundsForRealm addObject:[ExploreObservationSoundRealm valueForMantleModel:mtlSound]];
        }
        value[@"observationSounds"] = [NSArray arrayWithArray:soundsForRealm];
    }
    
    if (mtlModel.comments) {
        NSMutableArray *ecrs = [NSMutableArray array];
        for (ExploreComment *ec in mtlModel.comments) {
            [ecrs addObject:[ExploreCommentRealm valueForMantleModel:ec]];
        }
        value[@"comments"] = [NSArray arrayWithArray:ecrs];
    }
    
    if (mtlModel.identifications) {
        NSMutableArray *eirs = [NSMutableArray array];
        for (ExploreIdentification *ei in mtlModel.identifications) {
            [eirs addObject:[ExploreIdentificationRealm valueForMantleModel:ei]];
        }
        value[@"identifications"] = [NSArray arrayWithArray:eirs];
    }
    
    if (mtlModel.faves) {
        NSMutableArray *efrs = [NSMutableArray array];
        for (ExploreFave *ef in mtlModel.faves) {
            [efrs addObject:[ExploreFaveRealm valueForMantleModel:ef]];
        }
        value[@"faves"] = [NSArray arrayWithArray:efrs];
    }
    
    if (mtlModel.observationFieldValues) {
        NSMutableArray *ofvs = [NSMutableArray array];
        for (ExploreObsFieldValue *eofv in mtlModel.observationFieldValues) {
            [ofvs addObject:[ExploreObsFieldValueRealm valueForMantleModel:eofv]];
        }
        value[@"observationFieldValues"] = [NSArray arrayWithArray:ofvs];
    }
    
    if (mtlModel.projectObservations) {
        NSMutableArray *pos = [NSMutableArray array];
        for (ExploreProjectObservation *epo in mtlModel.projectObservations) {
            [pos addObject:[ExploreProjectObservationRealm valueForMantleModel:epo]];
        }
        value[@"projectObservations"] = [NSArray arrayWithArray:pos];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel error:(NSError *__autoreleasing *)errorPtr {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"observationId"] = [cdModel valueForKey:@"recordID"];
    } else {
        // this is an uploadable, un-uploaded obs can have a record
        // id of nil/zero
        value[@"observationId"] = @(0);
    }
    
    if ([cdModel valueForKey:@"uuid"]) {
        value[@"uuid"] = [cdModel valueForKey:@"uuid"];
    } else {
        // uuid is the primary key, cannot be nil for realm obs
        value[@"uuid"] = [[[NSUUID UUID] UUIDString] lowercaseString];
    }
    
    // these values can be nil in the model
    if ([cdModel valueForKey:@"speciesGuess"]) {
        value[@"speciesGuess"] = [cdModel valueForKey:@"speciesGuess"];
    }

    if ([cdModel valueForKey:@"inatDescription"]) {
        value[@"inatDescription"] = [cdModel valueForKey:@"inatDescription"];
    }
    
    if ([cdModel valueForKey:@"timeObservedAt"]) {
        value[@"timeObserved"] = [cdModel valueForKey:@"timeObservedAt"];
    } else if ([cdModel valueForKey:@"localObservedOn"]) {
        value[@"timeObserved"] = [cdModel valueForKey:@"localObservedOn"];
    }
    
    if ([cdModel valueForKey:@"placeGuess"]) {
        value[@"placeGuess"] = [cdModel valueForKey:@"placeGuess"];
    }
    
    if ([cdModel valueForKey:@"latitude"]) {
        value[@"latitude"] = [cdModel valueForKey:@"latitude"];
    } else {
        value[@"latitude"] = @(kCLLocationCoordinate2DInvalid.latitude);
    }
    
    if ([cdModel valueForKey:@"longitude"]) {
        value[@"longitude"] = [cdModel valueForKey:@"longitude"];
    } else {
        value[@"longitude"] = @(kCLLocationCoordinate2DInvalid.longitude);
    }

    if ([cdModel valueForKey:@"positionalAccuracy"]) {
        value[@"publicPositionalAccuracy"] = [cdModel valueForKey:@"positionalAccuracy"];
    } else {
        value[@"publicPositionalAccuracy"] = @(-1);
    }
    
    if ([cdModel valueForKey:@"privatePositionalAccuracy"]) {
        value[@"privatePositionalAccuracy"] = [cdModel valueForKey:@"privatePositionalAccuracy"];
    } else {
        value[@"privatePositionalAccuracy"] = @(-1);
    }
    
    if ([cdModel valueForKey:@"captive"]) {
        value[@"captive"] = [cdModel valueForKey:@"captive"];
    } else {
        value[@"captive"] = @(NO);
    }
    
    if ([cdModel valueForKey:@"ownersIdentificationFromVision"]) {
        value[@"ownersIdentificationFromVision"] = [cdModel valueForKey:@"ownersIdentificationFromVision"];
    } else {
        value[@"ownersIdentificationFromVision"] = @(NO);
    }
    
    value[@"coordinatesObscured"] = @(NO);
    
    // mappings that require transformation
    if ([cdModel valueForKey:@"dataQuality"]) {
        NSDictionary *dataQualityMappings = @{
            @"casual": @(ObsDataQualityCasual),
            @"needs_id": @(ObsDataQualityNeedsID),
            @"research": @(ObsDataQualityResearch),
        };
        value[@"dataQuality"] = [dataQualityMappings valueForKey:[cdModel valueForKey:@"qualityGrade"]];
    }
    
    if (![value valueForKey:@"dataQuality"]) {
        value[@"dataQuality"] = @(ObsDataQualityNone);
    }
    
    if ([cdModel valueForKey:@"syncedAt"]) {
        value[@"timeSynced"] = [cdModel valueForKey:@"syncedAt"];
    }
    
    if ([cdModel valueForKey:@"localUpdatedAt"]) {
        value[@"timeUpdatedLocally"] = [cdModel valueForKey:@"localUpdatedAt"];
    }

    if ([cdModel valueForKey:@"createdAt"]) {
        value[@"timeCreated"] = [cdModel valueForKey:@"createdAt"];
    } else if ([cdModel valueForKey:@"localCreatedAt"]) {
        value[@"timeCreated"] = [cdModel valueForKey:@"localCreatedAt"];
    }
    
    if ([cdModel valueForKey:@"geoprivacy"]) {
        value[@"geoprivacy"] = [cdModel valueForKey:@"geoprivacy"];
    }

    // to-one relationships
    if ([cdModel valueForKey:@"taxon"]) {
        id taxonValue = [ExploreTaxonRealm valueForCoreDataModel:[cdModel valueForKey:@"taxon"]];
        if (taxonValue) {
            value[@"taxon"] = taxonValue;
        }
    } else if ([cdModel valueForKey:@"taxonID"]) {
        NSInteger taxonId = [[cdModel valueForKey:@"taxonID"] integerValue];
        ExploreTaxonRealm *taxon = [ExploreTaxonRealm objectForPrimaryKey:@(taxonId)];
        if (taxon) {
            NSMutableDictionary *mutableTaxonValue = [[ExploreTaxonRealm valueForRealmModel:taxon] mutableCopy];
            // skip taxon photos during migration
            mutableTaxonValue[@"taxonPhotos"] = nil;
            id taxonValue = [NSDictionary dictionaryWithDictionary:mutableTaxonValue];
            if (taxonValue) {
                value[@"taxon"] = taxonValue;
            } else {
                // fallback
                NSDictionary *taxonValue = @{
                    @"taxonId": @(taxonId),
                    @"rankLevel": @(0),             // required or realm will crash
                    @"observationCount": @(0),      // required or realm will crash
                };
                value[@"taxon"] = taxonValue;
            }
        } else {
            // fallback
            NSDictionary *taxonValue = @{
                @"taxonId": @(taxonId),
                @"rankLevel": @(0),                 // required or realm will crash
                @"observationCount": @(0),          // required or realm will crash
            };
            value[@"taxon"] = taxonValue;
        }
    }
    
    // to-many relationships
    if ([cdModel valueForKey:@"observationPhotos"]) {
        NSMutableArray *photosValue = [NSMutableArray array];
        for (id cdPhoto in [cdModel valueForKey:@"observationPhotos"]) {
            id photoValue = [ExploreObservationPhotoRealm valueForCoreDataModel:cdPhoto];
            if (photoValue) {
                [photosValue addObject:photoValue];
            }
        }
        value[@"observationPhotos"] = [NSArray arrayWithArray:photosValue];
    }
    
    if ([cdModel valueForKey:@"identifications"]) {
        NSMutableArray *identificationsValue = [NSMutableArray array];
        for (id cdIdentification in [cdModel valueForKey:@"identifications"]) {
            id idValue = [ExploreIdentificationRealm valueForCoreDataModel:cdIdentification];
            if (idValue) {
                [identificationsValue addObject:idValue];
            }
        }
        value[@"identifications"] = [NSArray arrayWithArray:identificationsValue];
    }
    
    if ([cdModel valueForKey:@"comments"]) {
        NSMutableArray *commentsValue = [NSMutableArray array];
        for (id cdComment in [cdModel valueForKey:@"comments"]) {
            id commentValue = [ExploreCommentRealm valueForCoreDataModel:cdComment];
            if (commentValue) {
                [commentsValue addObject:commentValue];
            }
        }
        value[@"comments"] = [NSArray arrayWithArray:commentsValue];
    }

    if ([cdModel valueForKey:@"observationFieldValues"]) {
        NSMutableArray *ofvsValue = [NSMutableArray array];
        for (id cdOfv in [cdModel valueForKey:@"observationFieldValues"]) {
            id ofvValue = [ExploreObsFieldValueRealm valueForCoreDataModel:cdOfv];
            if (ofvValue) {
                [ofvsValue addObject:ofvValue];
            }
        }
        value[@"observationFieldValues"] = [NSArray arrayWithArray:ofvsValue];
    }
    
    if ([cdModel valueForKey:@"projectObservations"]) {
        NSMutableArray *posValue = [NSMutableArray array];
        for (id cdPo in [cdModel valueForKey:@"projectObservations"]) {
            id poValue = [ExploreProjectObservationRealm valueForCoreDataModel:cdPo];
            if (poValue) {
                [posValue addObject:poValue];
            }
        }
        value[@"projectObservations"] = [NSArray arrayWithArray:posValue];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}


+ (RLMResults *)myObservations {
    // for now, just return everything
    return [self allObjects];
}

+(NSString *)primaryKey {
    return @"uuid";
}

- (CLLocationCoordinate2D)location {
    if (self.latitude == 0.0 || self.longitude == 0.0) {
        return kCLLocationCoordinate2DInvalid;
    } else {
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(self.latitude, self.longitude);
        if (CLLocationCoordinate2DIsValid(loc)) {
            return loc;
        } else {
            return kCLLocationCoordinate2DInvalid;
        }
    }
}

- (NSArray *)observationMedia {
    NSArray *photos = [self sortedObservationPhotos];
    NSArray *sounds = [[self observationSounds] valueForKey:@"self"];
    
    NSMutableArray *media = [NSMutableArray arrayWithArray:photos];
    [media addObjectsFromArray:sounds];
    
    return [NSArray arrayWithArray:media];
}

- (CLLocationCoordinate2D)privateLocation {
    if (self.privateLatitude == 0.0 || self.privateLongitude == 0.0) {
        return kCLLocationCoordinate2DInvalid;
    } else {
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(self.privateLatitude, self.privateLongitude);
        if (CLLocationCoordinate2DIsValid(loc)) {
            return loc;
        } else {
            return kCLLocationCoordinate2DInvalid;
        }
    }
}


- (CLLocationAccuracy)positionalAccuracy {
    if (self.privatePositionalAccuracy != 0) {
        return self.privatePositionalAccuracy;
    } else if (self.publicPositionalAccuracy != 0) {
        return self.publicPositionalAccuracy;
    } else {
        return 0;
    }
}

- (NSArray *)sortedActivity {
    NSArray *comments = [[self comments] valueForKey:@"self"];
    NSArray *identifications = [[self identifications] valueForKey:@"self"];
    
    NSArray *activity = [comments arrayByAddingObjectsFromArray:identifications];
    NSSortDescriptor *createdAtSort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    
    return [activity sortedArrayUsingDescriptors:@[ createdAtSort ]];    
}

- (NSArray *)sortedFaves {
    NSArray *faves = [[self faves] valueForKey:@"self"];
    NSSortDescriptor *createdAtSort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    return [faves sortedArrayUsingDescriptors:@[ createdAtSort ]];
}

- (NSArray *)sortedProjectObservations {
    // safely convert to array
    NSArray *projectObservations = [[self projectObservations] valueForKey:@"self"];
    NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:@"project.title" ascending:YES];
    return [projectObservations sortedArrayUsingDescriptors:@[ titleSort ]];
}

- (ExploreTaxonRealm *)exploreTaxonRealm {
    return self.taxon;
}

- (ExploreObsFieldValueRealm *)valueForObsField:(ExploreObsFieldRealm *)field {
    for (ExploreObsFieldValueRealm *ofv in self.observationFieldValues) {
        if (ofv.obsField.obsFieldId == field.obsFieldId) {
            return ofv;
        }
    }
    
    return nil;
}

- (NSInteger)activityCount {
    if (self.taxon) {
        if (self.identifications.firstObject.identifier.userId == self.user.userId) {
            // skip the first  identification if it was made by the observer
            // we don't consider it part of the "activity" on this observation
            return MAX(0, self.sortedActivity.count - 1);
        }
    }

    return MAX(0, self.sortedActivity.count);
}

- (BOOL)isEditable {
    return YES;
}

- (NSInteger)inatRecordId {
    return self.observationId;
}

- (NSInteger)userID {
    return self.user.userId;
}

- (NSString *)username {
    return self.user.login;
}

- (NSURL *)userThumbUrl {
    return self.user.userIcon;
}

- (NSDate *)observedOn {
    return self.timeObserved;
}

- (NSString *)observedOnShortString {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return [formatter stringFromDate:self.timeObserved];
}

- (NSArray *)sortedObservationPhotos {
    if (self.realm) {
        // object is managed, can search on rlmresults
        RLMSortDescriptor *positionSort = [RLMSortDescriptor sortDescriptorWithKeyPath:@"position" ascending:YES];
        RLMResults *sortedPhotos = [self.observationPhotos sortedResultsUsingDescriptors:@[ positionSort ]];
        // convert to NSArray
        return [sortedPhotos valueForKey:@"self"];
    } else {
        // object is unmanaged, have to convert to an array before searching
        NSArray *photos = [self.observationPhotos valueForKey:@"self"];
        NSSortDescriptor *positionSort = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        return [photos sortedArrayUsingDescriptors:@[ positionSort ]];
    }
}

- (NSInteger)taxonRecordID {
    return self.taxon.taxonId;
}

- (NSString *)iconicTaxonName {
    return self.taxon.iconicTaxonName;
}

- (CLLocationCoordinate2D)visibleLocation {
    if (CLLocationCoordinate2DIsValid(self.privateLocation)) {
        return self.privateLocation;
    } else if (CLLocationCoordinate2DIsValid(self.location)) {
        return self.location;
    } else {
        return kCLLocationCoordinate2DInvalid;
    }
}

- (CLLocationAccuracy)visiblePositionalAccuracy {
    if (self.privatePositionalAccuracy != 0) {
        return self.privatePositionalAccuracy;
    } else {
        return self.publicPositionalAccuracy;
    }
}

- (NSString *)observedOnStringForUploading {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
        [formatter setDateFormat:@"EEE MMM dd yyyy HH:mm:ss 'GMT'Z (zzz)"];
        
        // per #128 and https://groups.google.com/d/topic/inaturalist/8tE0QTT_kzc/discussion
        // the server doesn't want the observed_on field to be localized
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    }

    return [formatter stringFromDate:self.timeObserved];
}

#pragma mark - Uploadable

// TODO: implement uploadable

- (NSArray *)childrenNeedingUpload {
    NSMutableArray *recordsToUpload = [NSMutableArray array];
    
    for (ExploreObservationPhotoRealm *op in self.observationPhotos) {
        if ([op needsUpload]) {
            [recordsToUpload addObject:op];
        }
    }
    
    for (ExploreObservationSoundRealm *os in self.observationSounds) {
        if ([os needsUpload]) {
            [recordsToUpload addObject:os];
        }
    }
    
    for (ExploreObsFieldValueRealm *ofv in self.observationFieldValues) {
        if ([ofv needsUpload]) {
            [recordsToUpload addObject:ofv];
        }
    }
    
    for (ExploreProjectObservationRealm *po in self.projectObservations) {
        if ([po needsUpload]) {
            [recordsToUpload addObject:po];
        }
    }
    
    return [NSArray arrayWithArray:recordsToUpload];
}

- (BOOL)needsUpload {
    return self.timeSynced == nil || [self.timeSynced timeIntervalSinceDate:self.timeUpdatedLocally] < 0;
}

+ (NSArray *)needingUpload {
    NSMutableArray *obsNeedingUpload = [NSMutableArray array];
    
    for (ExploreObservationRealm *obs in [self.class allObjects]) {
        if (obs.needsUpload) {
            [obsNeedingUpload addObject:obs];
        } else if ([[obs childrenNeedingUpload] count] > 0) {
            [obsNeedingUpload addObject:obs];
        }
    }
    
    NSArray *sorts = @[ [NSSortDescriptor sortDescriptorWithKey:@"timeCreated" ascending:YES] ];
    [obsNeedingUpload sortUsingDescriptors:sorts];
    
    return [NSArray arrayWithArray:obsNeedingUpload];
}

- (NSDictionary *)uploadableRepresentation {
    NSDictionary *mapping = @{
                              @"speciesGuess": @"species_guess",
                              @"inatDescription": @"description",
                              @"observedOnStringForUploading": @"observed_on_string",
                              @"placeGuess": @"place_guess",
                              @"latitude": @"latitude",
                              @"longitude": @"longitude",
                              @"positionalAccuracy": @"positional_accuracy",
                              @"taxonRecordID": @"taxon_id",
                              @"geoprivacy": @"geoprivacy",
                              @"uuid": @"uuid",
                              @"captive": @"captive_flag",
                              @"ownersIdentificationFromVision": @"owners_identification_from_vision",
                              };
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    for (NSString *key in mapping) {
        if ([self valueForKey:key]) {
            NSString *mappedName = mapping[key];
            
            BOOL found = NO;
            for (RLMProperty *property in self.objectSchema.properties) {
                if ([property.name isEqualToString:key]) {
                    found = YES;
                    if (property.type == RLMPropertyTypeBool) {
                        mutableParams[mappedName] = [[self valueForKey:key] boolValue] ? @"true" : @"false";
                    } else {
                        mutableParams[mappedName] = [self valueForKey:key];
                    }
                    break;
                }
            }
            if (!found) {
                mutableParams[mappedName] = [self valueForKey:key];
            }
        } else {
            // no value, for string properties we send empty string instead
            // of sending nothing
            NSString *mappedName = mapping[key];
            BOOL found = NO;
            for (RLMProperty *property in self.objectSchema.properties) {
                if ([property.name isEqualToString:key]) {
                    found = YES;
                    mutableParams[mappedName] = @"";
                    break;
                }
            }
        }
    }
    
    NSArray *badZeros = @[ @"taxon_id", @"latitude", @"longitude", @"positional_accuracy" ];
    for (NSString *badZero in badZeros) {
        // trim out bad values, like zero for latitude or taxon_id
        if ([mutableParams[badZero] isEqual:@(0)]) {
            mutableParams[badZero] = nil;
        }
    }
    
    NSArray *coordinateKeys = @[ @"latitude", @"longitude" ];
    for (NSString *coordinateKey in coordinateKeys) {
        // trim out invalid coordinate values
        if ([mutableParams[coordinateKey] isEqual:@(kCLLocationCoordinate2DInvalid.latitude)]) {
            mutableParams[coordinateKey] = nil;
        }
    }
    
    // return an immutable copy
    // ignore_photos is required to avoid clobbering obs photos
    // when updating an observation via the node endpoint
    // same with ignore_sounds?
    return @{
             @"observation": [NSDictionary dictionaryWithDictionary:mutableParams],
             @"ignore_photos": @(YES),
             @"ignore_sounds": @(YES),
             };
}

+ (NSString *)endpointName {
    return @"observations";
}

-(void)setRecordId:(NSInteger)newRecordId {
    self.observationId = newRecordId;
}

- (NSInteger)recordId {
    return self.observationId;
}

- (RLMResults *)updatesForObservation {
    return [ExploreUpdateRealm objectsWhere:@"resourceId == %ld", self.observationId];
}

- (RLMResults *)unseenUpdatesForObservation {
    return [ExploreUpdateRealm objectsWhere:@"resourceId == %ld AND viewed == FALSE", self.observationId];
}

- (BOOL)hasUnviewedActivityBool {
    return [[self unseenUpdatesForObservation] count] > 0;
}

- (void)setSyncedForSelfAndChildrenAt:(NSDate *)syncDate {
    self.timeSynced = syncDate;
    
    for (ExploreObservationPhotoRealm *op in self.observationPhotos) {
        op.timeSynced = syncDate;
    }
    
    for (ExploreObservationSoundRealm *os in self.observationSounds) {
        os.timeSynced = syncDate;
    }
    
    for (ExploreProjectObservationRealm *po in self.projectObservations) {
        po.timeSynced = syncDate;
    }
    
    for (ExploreObsFieldValueRealm *ofv in self.observationFieldValues) {
        ofv.timeSynced = syncDate;
    }
}

+ (void)syncedDelete:(ExploreObservationRealm *)observation {
    RLMRealm *realm = [observation realm];
    if (realm) {
        [realm beginWriteTransaction];
        
        // cached filesystem images
        for (ExploreObservationPhotoRealm *photo in observation.observationPhotos) {
            [photo deleteFileSystemAssociations];
        }
        
        // cached filesystem sound files
        for (ExploreObservationSoundRealm *sound in observation.observationSounds) {
            [sound deleteFileSystemAssociations];
        }
        
        // the server will cascade delete these for us
        // so just cascade the local stuff
        [realm deleteObjects:observation.observationPhotos];
        [realm deleteObjects:observation.observationSounds];
        [realm deleteObjects:observation.projectObservations];
        [realm deleteObjects:observation.observationFieldValues];
        [realm deleteObjects:observation.comments];
        [realm deleteObjects:observation.identifications];
        
        // create a deleted record for the observation
        ExploreDeletedRecord *dr = [observation deletedRecordForModel];
        [realm addOrUpdateObject:dr];
        
        // delete the observation
        [realm deleteObject:observation];
        [realm commitWriteTransaction];
    }
}

+ (void)deleteWithoutSync:(ExploreObservationRealm *)observation {
    if (observation.realm) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        
        // cascade, but safely
        // only delete stuff from realm that's actually in realm
        for (ExploreObservationPhotoRealm *op in observation.observationPhotos) {
            if (op.realm) {
                [op deleteFileSystemAssociations];
                [realm deleteObject:op];
            }
        }
        
        for (ExploreObservationSoundRealm *sound in observation.observationSounds) {
            if (sound.realm) {
                [sound deleteFileSystemAssociations];
                [realm deleteObject:sound];
            }
        }
        
        for (ExploreProjectObservationRealm *po in observation.projectObservations) {
            if (po.realm) {
                [realm deleteObject:po];
            }
        }
        
        for (ExploreObsFieldValueRealm *ofv in observation.observationFieldValues) {
            if (ofv.realm) {
                [realm deleteObject:ofv];
            }
        }
        
        for (ExploreCommentRealm *comment in observation.comments) {
            if (comment.realm) {
                [realm deleteObject:comment];
            }
        }
        
        for (ExploreIdentificationRealm *identification in observation.identifications) {
            if (identification.realm) {
                [realm deleteObject:identification];
            }
        }
                
        // delete the model object
        [realm deleteObject:observation];
        [realm commitWriteTransaction];
    }
}

- (ExploreDeletedRecord *)deletedRecordForModel {
    ExploreDeletedRecord *dr = [[ExploreDeletedRecord alloc] initWithRecordId:self.recordId
                                                                    modelName:@"Observation"];
    dr.endpointName = [self.class endpointName];
    dr.synced = NO;
    return dr;
}


- (instancetype)standaloneCopyWithMedia {
    ExploreObservationRealm *copy = [[ExploreObservationRealm alloc] initWithValue:self];
    
    // remove photo relations, since they were shallowly copied
    [copy.observationPhotos removeAllObjects];
    
    // remove sound relations, since they were shallowly copied
    [copy.observationSounds removeAllObjects];
    
    // re-add photo relations, with shallow copies
    for (ExploreObservationPhotoRealm *photo in self.observationPhotos) {
        ExploreObservationPhotoRealm *photoCopy = [[ExploreObservationPhotoRealm alloc] initWithValue:photo];
        [copy.observationPhotos addObject:photoCopy];
    }
    
    // re-add sound relations, with shallow copies
    for (ExploreObservationSoundRealm *sound in self.observationSounds) {
        ExploreObservationSoundRealm *soundCopy = [[ExploreObservationSoundRealm alloc] initWithValue:sound];
        [copy.observationSounds addObject:soundCopy];
    }
    
    return copy;
}

- (ObsTrueCoordinateVisibility)trueCoordinateVisibility {
    // if it's in realm, it belongs to the logged in user, so we
    // should always have the true coordinates
    return ObsTrueCoordinatePrivacyVisible;
}

@end
