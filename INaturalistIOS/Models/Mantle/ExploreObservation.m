//
//  ExploreObservation.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreObservation.h"
#import "ExploreComment.h"
#import "ExploreIdentification.h"
#import "ExploreFave.h"
#import "ExploreObservationPhoto.h"
#import "ExploreUser.h"
#import "ExploreTaxon.h"
#import "ExploreTaxonRealm.h"
#import "ExploreProjectObservation.h"
#import "ExploreObsFieldValue.h"
#import "ExploreObservationSound.h"

@implementation ExploreObservation

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
    // set defaults for these
    NSDictionary *defaults = @{
        @"location": [NSValue valueWithMKCoordinate:kCLLocationCoordinate2DInvalid],
        @"privateLocation": [NSValue valueWithMKCoordinate:kCLLocationCoordinate2DInvalid],
    };
    dictionaryValue = [defaults mtl_dictionaryByAddingEntriesFromDictionary:dictionaryValue];
    return [super initWithDictionary:dictionaryValue error:error];
}


+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"observationId": @"id",
             @"location": @"location",
             @"privateLocation": @"private_location",
             @"inatDescription": @"description",
             @"speciesGuess": @"species_guess",
             @"timeObserved": @"time_observed_at",
             @"observedTimeZone": @"observed_time_zone",
             @"dateObserved": @"observed_on",
             @"timeCreated": @"created_at",
             @"identificationsCount": @"identifications_count",
             @"commentsCount": @"comments_count",
             @"mappable": @"mappable",
             @"publicPositionalAccuracy": @"public_positional_accuracy",
             @"privatePositionalAccuracy": @"positional_accuracy",
             @"coordinatesObscured": @"obscured",
             @"placeGuess": @"place_guess",
             @"user": @"user",
             @"observationPhotos": @"observation_photos",
             @"observationSounds": @"observation_sounds",
             @"comments": @"comments",
             @"identifications": @"identifications",
             @"faves": @"faves",
             @"projectObservations": @"project_observations",
             @"taxon": @"taxon",
             @"dataQuality": @"quality_grade",
             @"uuid": @"uuid",
             @"captive": @"captive",
             @"geoprivacy": @"geoprivacy",
             @"ownersIdentificationFromVision": @"owners_identification_from_vision",
             @"observationFieldValues": @"ofvs",
             };
}

+ (NSValueTransformer *)dataQualityJSONTransformer {
    NSDictionary *dataQualityMappings = @{
        @"casual": @(ObsDataQualityCasual),
        @"needs_id": @(ObsDataQualityNeedsID),
        @"research": @(ObsDataQualityResearch),
    };
    
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:dataQualityMappings];
}

+ (NSValueTransformer *)timeObservedJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)dateObservedJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}


+ (NSValueTransformer *)timeCreatedJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)observationPhotosJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreObservationPhoto.class];
}

+ (NSValueTransformer *)observationSoundsJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreObservationSound.class];
}

+ (NSValueTransformer *)commentsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreComment.class];
}

+ (NSValueTransformer *)identificationsJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreIdentification.class];
}

+ (NSValueTransformer *)favesJSONTransformer {
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreFave.class];
}

+ (NSValueTransformer *)projectObservationsJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreProjectObservation.class];
}

+ (NSValueTransformer *)observationFieldValuesJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreObsFieldValue.class];
}

+ (NSValueTransformer *)taxonJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreTaxon.class];
}

+ (NSValueTransformer *)userJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

+ (NSValueTransformer *)locationJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(NSString *locationCoordinateString) {
        NSArray *c = [locationCoordinateString componentsSeparatedByString:@","];
        if (c.count == 2) {
            CLLocationDegrees latitude = [((NSString *)c[0]) doubleValue];
            CLLocationDegrees longitude = [((NSString *)c[1]) doubleValue];
            CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude, longitude);
            return [NSValue valueWithMKCoordinate:coords];
        } else {
            NSValue *val = [NSValue valueWithMKCoordinate:kCLLocationCoordinate2DInvalid];
            return val;
        }
    }];
}

+ (NSValueTransformer *)privateLocationJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(NSString *locationCoordinateString) {
        NSArray *c = [locationCoordinateString componentsSeparatedByString:@","];
        if (c.count == 2) {
            CLLocationDegrees latitude = [((NSString *)c[0]) doubleValue];
            CLLocationDegrees longitude = [((NSString *)c[1]) doubleValue];
            CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude, longitude);
            return [NSValue valueWithMKCoordinate:coords];
        } else {
            NSValue *val = [NSValue valueWithMKCoordinate:kCLLocationCoordinate2DInvalid];
            return val;
        }
    }];
}



- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"identificationsCount"]) {
        self.identificationsCount = 0;
    } else if ([key isEqualToString:@"commentsCount"]) {
        self.commentsCount = 0;
   	} else if ([key isEqualToString:@"mappable"]) {
        self.mappable = NO;
    } else if ([key isEqualToString:@"obscured"]) {
        self.coordinatesObscured = NO;
    } else if ([key isEqualToString:@"publicPositionalAccuracy"]) {
        self.publicPositionalAccuracy = 0;
    } else if ([key isEqualToString:@"privatePositionalAccuracy"]) {
        self.privatePositionalAccuracy = 0;
    } else if ([key isEqualToString:@"location"]) {
        self.location = kCLLocationCoordinate2DInvalid;
    } else if ([key isEqualToString:@"privateLocation"]) {
        self.privateLocation = kCLLocationCoordinate2DInvalid;
    } else if ([key isEqualToString:@"captive"]) {
        self.captive = NO;
    } else if ([key isEqualToString:@"ownersIdentificationFromVision"]) {
        self.ownersIdentificationFromVision = NO;
    } else {
        [super setNilValueForKey:key];
    }
}

- (CLLocationAccuracy)positionalAccuracy {
    if (self.privatePositionalAccuracy != 0) {
        return self.privatePositionalAccuracy;
    } else {
        return self.publicPositionalAccuracy;
    }
}

- (ExploreTaxonRealm *)exploreTaxonRealm {
	RLMResults *results = [ExploreTaxonRealm objectsWhere:@"taxonId == %d", self.taxon.taxonId];
	return [results firstObject];
}

#pragma mark - Uploadable

- (NSArray *)childrenNeedingUpload {
    return @[];
}

- (BOOL)needsUpload {
    return false;
}

+ (NSArray *)needingUpload {
    return @[];
}

#pragma mark - ObservationVisualization

- (NSArray *)observationMedia {
    NSMutableArray *media = [NSMutableArray arrayWithArray:self.sortedObservationPhotos];
    [media addObjectsFromArray:self.observationSounds];
    return [NSArray arrayWithArray:media];
}

- (NSString *)iconicTaxonName {
    return self.taxon.iconicTaxonName;
}

- (BOOL)isEditable {
    return NO;
}

- (NSString *)username {
	return self.user.login;
}

- (NSURL *)userThumbUrl {
	return self.user.userIcon;
}

- (NSArray *)sortedProjectObservations {
    NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:@"project.title" ascending:YES];
    return [self.projectObservations sortedArrayUsingDescriptors:@[ titleSort ]];
}

- (NSArray *)sortedFaves {
    return [self.faves sortedArrayUsingComparator:^NSComparisonResult(ExploreFave *obj1, ExploreFave *obj2) {
        // newest first
        return [obj2.faveDate compare:obj1.faveDate];
    }];
}

- (NSArray *)sortedActivity {
    // don't show hidden content (ie content that's been moderated)
    NSPredicate *notHiddenPredicate = [NSPredicate predicateWithFormat:@"hidden = FALSE"];
    NSArray *unhiddenComments = [self.comments filteredArrayUsingPredicate:notHiddenPredicate];
    NSArray *unhiddenIds = [self.identifications filteredArrayUsingPredicate:notHiddenPredicate];

    NSArray *activity = [unhiddenComments arrayByAddingObjectsFromArray:unhiddenIds];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    NSArray *sortedActivity = [activity sortedArrayUsingDescriptors:@[ sortDescriptor ]];
    return sortedActivity;
}

- (NSString *)qualityGrade {
    switch (self.dataQuality) {
        case ObsDataQualityResearch:
            return @"research";
            break;
        case ObsDataQualityNeedsID:
            return @"needs_id";
            break;
        case ObsDataQualityCasual:
            return @"casual";
            break;
        default:
            return @"";
            break;
    }
}

- (NSDate *)observedOn {
    return self.dateObserved;
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

- (NSInteger)inatRecordId {
    return self.observationId;
}

- (NSInteger)recordId {
    return self.observationId;
}

- (BOOL)hasUnviewedActivityBool {
    return NO;
}

- (NSInteger)userID {
	return self.user.userId;
}

- (NSString *)sortable {
    return [NSString stringWithFormat:@"%f", self.timeObserved.timeIntervalSinceNow];
}

- (NSInteger)taxonRecordID {
	return self.taxon.taxonId;
}

- (NSString *)validationErrorMsg {
    return @"";
}

- (NSArray *)sortedObservationPhotos {
    return self.observationPhotos;
}

- (CLLocationDegrees)latitude {
    return self.location.latitude;
}

- (CLLocationDegrees)longitude {
    return self.location.longitude;
}

// we're putting observations in a set, and want to make sure they don't get added more than once.
// so override -isEqual: and -hash to make observation objects unique to the underlying observation.
- (BOOL)isEqual:(id)object {
    if (![[object class] isEqual:self.class])
        return NO;
    ExploreObservation *otherObs = (ExploreObservation *)object;
    
    return self.observationId == otherObs.observationId;
}

-(NSUInteger)hash {
    return self.observationId;
}

- (BOOL)commentsAndIdentificationsSynchronized {
    if (self.commentsCount != self.comments.count)
        return NO;
    if (self.identificationsCount != self.identifications.count)
        return NO;
    
    return YES;
}

- (CLLocationCoordinate2D)visibleLocation {
    
    if (CLLocationCoordinate2DIsValid(self.privateLocation)) {
        return self.privateLocation;
    } else {
        return self.location;
    }
}

- (CLLocationDistance)visiblePositionalAccuracy {
	return self.publicPositionalAccuracy;
}

- (NSInteger)activityCount {
    if (self.taxon) {
        return MAX(0, self.sortedActivity.count - 1);
    } else {
        return MAX(0, self.sortedActivity.count);
    }
}

#pragma mark - MKAnnotation coordinate

- (CLLocationCoordinate2D)coordinate {
    return [self visibleLocation];
}

- (ObsTrueCoordinateVisibility)trueCoordinateVisibility {
    if (self.coordinatesObscured) {
        if (CLLocationCoordinate2DIsValid(self.privateLocation)) {
            // obscured but we can see true coordinates
            return ObsTrueCoordinatePrivacyVisible;
        } else {
            if ([self.geoprivacy isEqualToString:@"private"]) {
                return ObsTrueCoordinatePrivacyHidden;
            } else {
                return ObsTrueCoordinatePrivacyObscured;
            }
        }
    } else {
        return ObsTrueCoordinatePrivacyVisible;
    }
}

@end
