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

@implementation ExploreObservation

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"observationId": @"id",
             @"location": @"location",
             @"privateLocation": @"private_location",
             @"inatDescription": @"description",
             @"speciesGuess": @"species_guess",
             @"timeObservedAt": @"time_observed_at",
             @"observedOn": @"observed_on",
             @"createdAt": @"created_at",
             @"qualityGrade": @"quality_grade",
             @"idPlease": @"id_please",
             @"identificationsCount": @"identifications_count",
             @"commentsCount": @"comments_count",
             @"favesCount": @"faves_count",
             @"mappable": @"mappable",
             @"publicPositionalAccuracy": @"public_positional_accuracy",
             @"coordinatesObscured": @"coordinates_obscured",
             @"placeGuess": @"place_guess",
             @"user": @"user",
             @"observationPhotos": @"photos",
             @"comments": @"comments",
             @"identifications": @"identifications",
             @"faves": @"faves",
             @"taxon": @"taxon",
             @"uuid": @"uuid",
             };
}

+ (NSValueTransformer *)geoprivacyJSONTransformer {
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
                                                                           @"": @(GeoprivacyOpen),
                                                                           @"obscured": @(GeoprivacyObscured),
                                                                           @"private": @(GeoprivacyPrivate)
                                                                           }];
}

+ (NSValueTransformer *)qualityGradeJSONTransformer {
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
                                                                           @"casual": @(ObsDataQualityCasual),
                                                                           @"needs_id": @(ObsDataQualityNeedsID),
                                                                           @"research": @(ObsDataQualityResearch),
                                                                           @"": @(ObsDataQualityNone)
                                                                           }];
}

+ (NSValueTransformer *)observationPhotosJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreObservationPhoto.class];
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

+ (NSValueTransformer *)taxonJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreTaxon.class];
}

+ (NSValueTransformer *)userJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    return dateFormatter;
}

+ (NSValueTransformer *)createdAtJSONTransformer {
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    
    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}


+ (NSValueTransformer *)timeObservedAtJSONTransformer {
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    
    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)observedOnJSONTransformer {
	static NSDateFormatter *_dateFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dateFormatter = [[NSDateFormatter alloc] init];
		_dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
		_dateFormatter.dateFormat = @"yyyy-MM-dd";
	});

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)locationJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(NSString *locationCoordinateString) {
    	NSArray *c = [locationCoordinateString componentsSeparatedByString:@","];
    	if (c.count == 2) {
    		CLLocationDegrees latitude = [((NSString *)c[0]) floatValue];
    		CLLocationDegrees longitude = [((NSString *)c[1]) floatValue];
            if (latitude != 0 && longitude != 0) {
                CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude, longitude);
                return [NSValue valueWithMKCoordinate:coords];
            } else {
                return nil;
            }
    	} else {
    		return nil;
    	}
    }];
}

+ (NSValueTransformer *)privateLocationJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(NSString *locationCoordinateString) {
        NSArray *c = [locationCoordinateString componentsSeparatedByString:@","];
        if (c.count == 2) {
            CLLocationDegrees latitude = [((NSString *)c[0]) floatValue];
            CLLocationDegrees longitude = [((NSString *)c[1]) floatValue];
            if (latitude != 0 && longitude != 0) {
                CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude, longitude);
                return [NSValue valueWithMKCoordinate:coords];
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }];
}


- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"idPlease"]) {
        self.idPlease = NO;
    } else if ([key isEqualToString:@"geoprivacy"]) {
    	self.geoprivacy = GeoprivacyOpen;
    } else if ([key isEqualToString:@"qualityGrade"]) {
    	self.qualityGrade = ObsDataQualityCasual;
    } else if ([key isEqualToString:@"identificationsCount"]) {
        self.identificationsCount = 0;
    } else if ([key isEqualToString:@"commentsCount"]) {
        self.commentsCount = 0;
    } else if ([key isEqualToString:@"favesCount"]) {
        self.favesCount = 0;
   	} else if ([key isEqualToString:@"mappable"]) {
        self.mappable = NO;
    } else if ([key isEqualToString:@"coordinatesObscured"]) {
        self.coordinatesObscured = NO;
    } else if ([key isEqualToString:@"publicPositionalAccuracy"]) {
        self.publicPositionalAccuracy = 0;
    } else if ([key isEqualToString:@"location"]) {
    	self.location = CLLocationCoordinate2DMake(-19999.0,-19999.0);
    } else if ([key isEqualToString:@"privateLocation"]) {
        self.privateLocation = CLLocationCoordinate2DMake(-19999.0,-19999.0);
    } else {
        [super setNilValueForKey:key];
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

- (BOOL)isCaptive {
	return self.captive;
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

- (CLLocationAccuracy)privatePositionalAccuracy {
    return 0;
}

- (NSArray *)sortedFaves {
    return [self.faves sortedArrayUsingComparator:^NSComparisonResult(ExploreFave *obj1, ExploreFave *obj2) {
        // newest first
        return [obj2.faveDate compare:obj1.faveDate];
    }];
    return @[];
}

- (NSArray *)sortedActivity {
    NSArray *activity = [self.comments arrayByAddingObjectsFromArray:self.identifications];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    NSArray *sortedActivity = [activity sortedArrayUsingDescriptors:@[ sortDescriptor ]];
    
    return sortedActivity;
}

- (NSInteger)activityCount {
    return self.identificationsCount + self.commentsCount;
}

- (NSString *)observedOnShortString {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return [formatter stringFromDate:self.observedOn];
}

- (NSInteger)inatRecordId {
    return self.observationId;
}

- (BOOL)hasUnviewedActivity {
    return NO;
}

- (NSInteger)userID {
	return self.user.userId;
}

- (NSString *)sortable {
    return [NSString stringWithFormat:@"%f", self.timeObservedAt.timeIntervalSinceNow];
}

- (NSInteger)taxonRecordID {
	return self.taxon.taxonId;
}

- (NSSet *)observationFieldValues {
    return [NSSet set];
}

- (BOOL)captive {
    return NO;
}

- (NSString *)validationErrorMsg {
    return @"";
}

- (NSString *)geoprivacy {
    return @"";
}

- (NSSet *)projectObservations {
    return [NSSet set];
}

- (NSArray *)sortedObservationPhotos {
    return self.observationPhotos;
}

- (CLLocationAccuracy)positionalAccuracy {
    return self.publicPositionalAccuracy;
}

- (CLLocationCoordinate2D)coordinate {
	return self.location;
}

- (CLLocationDegrees)latitude {
	if (CLLocationCoordinate2DIsValid(self.location)) {
		return self.location.latitude;
	} else {
        return 0.0;
	}
}

- (CLLocationDegrees)longitude {
	if (CLLocationCoordinate2DIsValid(self.location)) {
		return self.location.longitude;
	} else {
        return 0.0;
	}
}

- (CLLocationDegrees)privateLatitude {
    if (CLLocationCoordinate2DIsValid(self.privateLocation)) {
        return self.privateLocation.latitude;
    } else {
        return 0.0;
    }
}

- (CLLocationDegrees)privateLongitude {
    if (CLLocationCoordinate2DIsValid(self.privateLocation)) {
        return self.privateLocation.longitude;
    } else {
        return 0.0;
    }
}


- (NSString *)title {
    return nil;
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
