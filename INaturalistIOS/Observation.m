//
//  Observation.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/15/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "Observation.h"
#import "ObservationFieldValue.h"
#import "ObservationField.h"
#import "Taxon.h"
#import "Comment.h"
#import "Identification.h"
#import "ObservationPhoto.h"
#import "DeletedRecord.h"
#import "ProjectObservation.h"
#import "Fave.h"
#import "User.h"
#import "ExploreTaxonRealm.h"
#import "ExploreUpdateRealm.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKObjectMapping *defaultSerializationMapping = nil;

@implementation Observation

@dynamic speciesGuess;
@dynamic taxonID;
@dynamic inatDescription;
@dynamic latitude;
@dynamic longitude;
@dynamic positionalAccuracy;
@dynamic observedOn;
@dynamic localObservedOn;
@dynamic observedOnString;
@dynamic timeObservedAt;
@dynamic userID;
@dynamic placeGuess;
@dynamic idPlease;
@dynamic iconicTaxonID;
@dynamic iconicTaxonName;
@dynamic privateLatitude;
@dynamic privateLongitude;
@dynamic privatePositionalAccuracy;
@dynamic geoprivacy;
@dynamic qualityGrade;
@dynamic positioningMethod;
@dynamic positioningDevice;
@dynamic outOfRange;
@dynamic license;
@dynamic observationPhotos;
@dynamic observationFieldValues;
@dynamic projectObservations;
@dynamic taxon;
@dynamic commentsCount;
@dynamic identificationsCount;
@dynamic hasUnviewedActivity;
@dynamic comments;
@dynamic identifications;
@dynamic sortable;
@dynamic uuid;
@dynamic validationErrorMsg;
@dynamic captive;
@dynamic faves;
@dynamic favesCount;

+ (NSArray *)all
{
    return [self objectsWithFetchRequest:self.defaultDescendingSortedFetchRequest];
}

- (ExploreTaxonRealm *)exploreTaxonRealm {
	RLMResults *results = [ExploreTaxonRealm objectsWhere:@"taxonId == %d", self.taxonID.integerValue];
	return [results firstObject];
}

+ (Observation *)stub
{
    NSArray *speciesGuesses = [[NSArray alloc] initWithObjects:
                               @"House Sparrow", 
                               @"Mourning Dove", 
                               @"Amanita muscaria", 
                               @"Homo sapiens", nil];
    NSArray *placeGuesses = [[NSArray alloc] initWithObjects:
                             @"Berkeley, CA", 
                             @"Clinton, CT", 
                             @"Mount Diablo State Park, Contra Costa County, CA, USA", 
                             @"somewhere in nevada", nil];    
    Observation *o = [Observation object];
    o.speciesGuess = [speciesGuesses objectAtIndex:rand() % speciesGuesses.count];
    o.localObservedOn = [NSDate date];
    o.observedOnString = [Observation.jsDateFormatter stringFromDate:o.localObservedOn];
    o.placeGuess = [placeGuesses objectAtIndex:rand() % [placeGuesses count]];
    o.latitude = [NSNumber numberWithInt:rand() % 89];
    o.longitude = [NSNumber numberWithInt:rand() % 179];
    o.positionalAccuracy = [NSNumber numberWithInt:rand() % 500];
    o.inatDescription = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
    return o;
}

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[Observation class]
                                            inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"species_guess", @"speciesGuess",
         @"description", @"inatDescription",
         @"created_at_utc", @"createdAt",
         @"updated_at_utc", @"updatedAt",
         @"observed_on", @"observedOn",
         @"observed_on_string", @"observedOnString",
         @"time_observed_at_utc", @"timeObservedAt",
         @"place_guess", @"placeGuess",
         @"latitude", @"latitude",
         @"longitude", @"longitude",
         @"positional_accuracy", @"positionalAccuracy",
         @"private_latitude", @"privateLatitude",
         @"private_longitude", @"privateLongitude",
         @"private_positional_accuracy", @"privatePositionalAccuracy",
         @"taxon_id", @"taxonID",
         @"iconic_taxon_id", @"iconicTaxonID",
         @"iconic_taxon_name", @"iconicTaxonName",
		 @"comments_count", @"commentsCount",
		 @"identifications_count", @"identificationsCount",
         @"cached_votes_total", @"favesCount",
		 @"last_activity_at_utc", @"lastActivityAt",
         @"uuid", @"uuid",
         @"id_please", @"idPlease",
         @"geoprivacy", @"geoprivacy",
         @"user_id", @"userID",
         @"quality_grade", @"qualityGrade",
         @"captive_flag", @"captive",
         @"owners_identification_from_vision", @"ownersIdentificationFromVision",
         nil];
        [defaultMapping mapKeyPath:@"taxon" 
                    toRelationship:@"taxon" 
                       withMapping:[Taxon mapping]
                         serialize:NO];
		[defaultMapping mapKeyPath:@"comments"
                    toRelationship:@"comments"
                       withMapping:[Comment mapping]
                         serialize:NO];
		[defaultMapping mapKeyPath:@"identifications"
                    toRelationship:@"identifications"
                       withMapping:[Identification mapping]
                         serialize:NO];
        [defaultMapping mapKeyPath:@"observation_field_values"
                    toRelationship:@"observationFieldValues"
                       withMapping:[ObservationFieldValue mapping]
                         serialize:NO];
		[defaultMapping mapKeyPath:@"observation_photos"
                    toRelationship:@"observationPhotos"
                       withMapping:[ObservationPhoto mapping]
                         serialize:NO];
        [defaultMapping mapKeyPath:@"project_observations"
                    toRelationship:@"projectObservations"
                       withMapping:[ProjectObservation mapping]
                         serialize:NO];
        [defaultMapping mapKeyPath:@"faves"
                    toRelationship:@"faves"
                       withMapping:[Fave mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [[RKManagedObjectMapping mappingForClass:[Observation class]
                                                          inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]] inverseMapping];
        [defaultSerializationMapping mapKeyPathsToAttributes:
         @"speciesGuess", @"observation[species_guess]",
         @"inatDescription", @"observation[description]",
         @"observedOnString", @"observation[observed_on_string]",
         @"placeGuess", @"observation[place_guess]",
         @"latitude", @"observation[latitude]",
         @"longitude", @"observation[longitude]",
         @"positionalAccuracy", @"observation[positional_accuracy]",
         @"taxonID", @"observation[taxon_id]",
         @"iconicTaxonID", @"observation[iconic_taxon_id]",
         @"idPlease", @"observation[id_please]",
         @"geoprivacy", @"observation[geoprivacy]",
         @"uuid", @"observation[uuid]",
         @"captive", @"observation[captive_flag]",
         @"ownersIdentificationFromVision", @"observation[owners_identification_from_vision]",
         nil];
    }
    return defaultSerializationMapping;
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // unsafe to fetch in -awakeFromInsert
    [self performSelector:@selector(computeLocalObservedOnAndSortable)
               withObject:nil
               afterDelay:0];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    
    // safe to use getters & setters in -awakeFromFetch
    [self computeLocalObservedOnAndSortable];
}

- (void)computeLocalObservedOnAndSortable {
    if (!self.localObservedOn) {
        if (self.timeObservedAt) self.localObservedOn = self.timeObservedAt;
        else if (self.observedOn) self.localObservedOn = self.observedOn;
    }
    
    NSDate *sortableDate = self.localCreatedAt ? self.localCreatedAt : self.createdAt;
    self.sortable = [NSString stringWithFormat:@"%f", sortableDate.timeIntervalSinceReferenceDate];
}

- (NSArray *)sortedObservationPhotos
{
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:YES];
    NSSortDescriptor *sortDescriptor3 = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:YES];
    return [self.observationPhotos 
            sortedArrayUsingDescriptors:
            [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, sortDescriptor3, nil]];
}

- (NSArray *)sortedProjectObservations
{
    NSSortDescriptor *titleSort = [[NSSortDescriptor alloc] initWithKey:@"project.title" ascending:YES];
    return [self.projectObservations sortedArrayUsingDescriptors:
            [NSArray arrayWithObjects:titleSort, nil]];
}

- (NSString *)observedOnPrettyString
{
    if (!self.localObservedOn) return @"Unknown";
    return [Observation.prettyDateFormatter stringFromDate:self.localObservedOn];
}

- (NSString *)observedOnShortString
{
    if (!self.localObservedOn) return @"";
    NSDateFormatter *fmt = Observation.shortDateFormatter;
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSCalendarUnitDay fromDate:self.localObservedOn toDate:now options:0];
    if (comps.day == 0) {
        fmt.dateStyle = NSDateFormatterNoStyle;
        fmt.timeStyle = NSDateFormatterShortStyle;
    } else {
        fmt.dateStyle = NSDateFormatterMediumStyle;
        fmt.timeStyle = NSDateFormatterNoStyle;
    }
    return [fmt stringFromDate:self.localObservedOn];
}

- (UIColor *)iconicTaxonColor
{
    if ([self.iconicTaxonName isEqualToString:@"Animalia"] || 
        [self.iconicTaxonName isEqualToString:@"Actinopterygii"] ||
        [self.iconicTaxonName isEqualToString:@"Amphibia"] ||
        [self.iconicTaxonName isEqualToString:@"Reptilia"] ||
        [self.iconicTaxonName isEqualToString:@"Aves"] ||
        [self.iconicTaxonName isEqualToString:@"Mammalia"]) {
        return [UIColor blueColor];
    } else if ([self.iconicTaxonName isEqualToString:@"Mollusca"] ||
               [self.iconicTaxonName isEqualToString:@"Insecta"] ||
               [self.iconicTaxonName isEqualToString:@"Arachnida"]) {
        return [UIColor orangeColor];
    } else if ([self.iconicTaxonName isEqualToString:@"Plantae"]) {
        return [UIColor greenColor];
    } else if ([self.iconicTaxonName isEqualToString:@"Protozoa"]) {
        return [UIColor purpleColor];
    } else if ([self.iconicTaxonName isEqualToString:@"Fungi"]) {
        return [UIColor redColor];
    } else {
        return [UIColor darkGrayColor];
    }
}

- (NSNumber *)taxonID
{
    [self willAccessValueForKey:@"taxonID"];
    if (!self.primitiveTaxonID || [self.primitiveTaxonID intValue] == 0) {
        [self setPrimitiveTaxonID:self.taxon.recordID];
    }
    [self didAccessValueForKey:@"taxonID"];
    return [self primitiveTaxonID];
}

- (NSNumber *)iconicTaxonName
{
    [self willAccessValueForKey:@"iconicTaxonName"];
    if (!self.primitiveIconicTaxonName) {
        [self setPrimitiveIconicTaxonName:[self.taxon primitiveValueForKey:@"iconicTaxonName"]];
    }
    [self didAccessValueForKey:@"iconicTaxonName"];
    return [self primitiveIconicTaxonName];
}

// TODO when we start storing public observations this needs to check whether the obs belongs
// to the signed in user
- (NSNumber *)visibleLatitude
{
    if (self.privateLatitude) {
        return self.privateLatitude;
    }
    return self.latitude;
}

- (NSNumber *)visibleLongitude
{
    if (self.privateLongitude) {
        return self.privateLongitude;
    }
    return self.longitude;
}

- (NSInteger)activityCount {
    if (self.taxonID) {
        return MAX(0, self.commentsCount.integerValue + self.identificationsCount.integerValue - 1);
    } else {
        return MAX(0, self.commentsCount.integerValue + self.identificationsCount.integerValue);
    }
}

// TODO: try forKey: instead of forKeyPath:
- (BOOL)validateValue:(inout __autoreleasing id *)ioValue forKeyPath:(NSString *)inKeyPath error:(out NSError *__autoreleasing *)outError {
	// for observations which are due to be synced, only update the value if the local value is empty
	if (self.needsSync && self.localUpdatedAt != nil && ![inKeyPath isEqualToString:@"recordID"]) {
		return ([self valueForKeyPath:inKeyPath] == nil);
	}
	return [super validateValue:ioValue forKeyPath:inKeyPath error:outError];
}

+ (NSFetchRequest *)defaultDescendingSortedFetchRequest
{
    NSFetchRequest *request = [self fetchRequest];
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sortable" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sd1, nil]];
    return request;
}

+ (NSFetchRequest *)defaultAscendingSortedFetchRequest
{
    NSFetchRequest *request = [self fetchRequest];
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sortable" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sd1, nil]];
    return request;
}

- (Observation *)prevObservation
{
    NSFetchRequest *request = [Observation defaultDescendingSortedFetchRequest];
    [request setPredicate:[NSPredicate predicateWithFormat:@"sortable < %@", self.sortable]];
    Observation *prev = [Observation objectWithFetchRequest:request];
    return prev;
}

- (Observation *)nextObservation
{
    NSFetchRequest *request = [Observation defaultAscendingSortedFetchRequest];
    [request setPredicate:[NSPredicate predicateWithFormat:@"sortable > %@", self.sortable]];
    Observation *next = [Observation objectWithFetchRequest:request];
    return next;
}

- (void)willSave
{
    [super willSave];
    
    if (!self.uuid && !self.recordID) {
        [self setPrimitiveValue:[[[NSUUID UUID] UUIDString] lowercaseString]
                         forKey:@"uuid"];
    }
}

- (void)prepareForDeletion
{
    if (self.syncedAt) {
        DeletedRecord *dr = [DeletedRecord object];
        dr.recordID = self.recordID;
        dr.modelName = NSStringFromClass(self.class);
    }
}

+ (NSArray *)needingUpload {
    // all observations that need sync are upload candidates
    NSMutableSet *needingUpload = [[NSMutableSet alloc] init];
    [needingUpload addObjectsFromArray:[self needingSync]];
    
    // also, all observations whose uploadable children need sync
    
    for (ObservationPhoto *op in [ObservationPhoto needingSync]) {
        if (op.observation) {
            [needingUpload addObject:op.observation];
        } else {
            [op destroy];
        }
    }
    
    for (ObservationFieldValue *ofv in [ObservationFieldValue needingSync]) {
        if (ofv.observation) {
            [needingUpload addObject:ofv.observation];
        } else {
            [ofv destroy];
        }
    }
    
    for (ProjectObservation *po in [ProjectObservation needingSync]) {
        if (po.observation) {
            [needingUpload addObject:po.observation];
        } else {
            [po destroy];
        }
    }
    
    return [[needingUpload allObjects] sortedArrayUsingComparator:^NSComparisonResult(INatModel *o1, INatModel *o2) {
        return [o1.localCreatedAt compare:o2.localCreatedAt];
    }];
}

- (BOOL)needsUpload {
    // needs upload if this obs needs sync
    if (self.needsSync) { return YES; }
    return NO;
}

- (NSArray *)childrenNeedingUpload {
    NSMutableArray *recordsToUpload = [NSMutableArray array];
    
    for (ObservationPhoto *op in self.observationPhotos) {
        if (op.needsSync) {
            [recordsToUpload addObject:op];
        }
    }
    for (ObservationFieldValue *ofv in self.observationFieldValues) {
        if (ofv.needsSync) {
            [recordsToUpload addObject:ofv];
        }
    }
    for (ProjectObservation *po in self.projectObservations) {
        if (po.needsSync) {
            [recordsToUpload addObject:po];
        }
    }
    
    return [NSArray arrayWithArray:recordsToUpload];
}

- (NSString *)presentableGeoprivacy {
    
    if ([self.geoprivacy isEqualToString:@"private"]) {
        return NSLocalizedString(@"Private", @"private geoprivacy");
    } else if ([self.geoprivacy isEqualToString:@"obscured"]) {
        return NSLocalizedString(@"Obscured", @"obscured geoprivacy");
    } else {
        return NSLocalizedString(@"Open", @"open geoprivacy");
    }
    
}

- (NSArray *)sortedFaves {
    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"faveDate" ascending:NO];
    return [self.faves sortedArrayUsingDescriptors:@[ dateSort ]];
}

- (NSArray *)sortedActivity {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    NSArray *allActivities = [self.comments.allObjects arrayByAddingObjectsFromArray:self.identifications.allObjects];
    return [allActivities sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (ObsDataQuality)dataQuality {
    if (self.recordID) {
        if ([self.qualityGrade isEqualToString:@"research"]) {
            return ObsDataQualityResearch;
        } else if ([self.qualityGrade isEqualToString:@"needs_id"]) {
            return ObsDataQualityNeedsID;
        } else {
            // must be casual?
            return ObsDataQualityCasual;
        }
    } else {
        // not uploaded yet
        return ObsDataQualityNone;
    }
}

#pragma mark - ObservationVisualization

- (BOOL)isCaptive {
	return [self.captive boolValue];
}

- (NSInteger)inatRecordId {
    return self.recordID.integerValue;
}

-(NSInteger)taxonRecordID {
    return self.taxonID.integerValue;
}

- (NSString *)username {
    User *user = [[User objectsWithPredicate:[NSPredicate predicateWithFormat:@"recordID == %d", self.userID.integerValue]] firstObject];
    return user.login;
}

- (NSURL *)userThumbUrl {
    User *user = [[User objectsWithPredicate:[NSPredicate predicateWithFormat:@"recordID == %d", self.userID.integerValue]] firstObject];
    return [NSURL URLWithString:user.userIconURL];
}

- (BOOL)isEditable {
    return YES;
}

- (CLLocationCoordinate2D)visibleLocation {
	if (self.privateLatitude && self.privateLatitude.floatValue != 0) {
		return CLLocationCoordinate2DMake(self.privateLatitude.floatValue, self.privateLongitude.floatValue);
	} else if (self.latitude && self.latitude.floatValue != 0) {
		return CLLocationCoordinate2DMake(self.latitude.floatValue, self.longitude.floatValue);
	} else {
		// invalid location
		return CLLocationCoordinate2DMake(-19999.0,-19999.0);
	}
}

- (CLLocationDistance)visiblePositionalAccuracy {
	if (self.privatePositionalAccuracy && self.privatePositionalAccuracy.integerValue != 0) {
		return self.privatePositionalAccuracy.integerValue;
	} else if (self.positionalAccuracy && self.positionalAccuracy.integerValue != 0) {
		return self.positionalAccuracy.integerValue;
	} else {
		return 0;
	}
}

- (BOOL)hasUnviewedActivityBool {
    return [self.hasUnviewedActivity boolValue] || [[self unseenUpdates] count] > 0;
}

- (RLMResults *)updates {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"resourceId == %ld",
                              self.recordID.integerValue];
    return [ExploreUpdateRealm objectsWithPredicate:predicate];
}

- (RLMResults *)unseenUpdates {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"resourceId == %ld and viewed == false",
                              self.recordID.integerValue];
    return [ExploreUpdateRealm objectsWithPredicate:predicate];
}

@end
