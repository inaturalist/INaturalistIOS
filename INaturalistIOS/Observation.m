//
//  Observation.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/15/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Observation.h"
#import "ObservationFieldValue.h"
#import "Taxon.h"
#import "Comment.h"
#import "Identification.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKObjectMapping *defaultSerializationMapping = nil;
static NSDateFormatter *prettyDateFormatter = nil;
static NSDateFormatter *shortDateFormatter = nil;
static NSDateFormatter *isoDateFormatter = nil;
static NSDateFormatter *jsDateFormatter = nil;

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

+ (NSArray *)all
{
    NSFetchRequest *request = [self fetchRequest];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"localObservedOn" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    return [self objectsWithFetchRequest:request];
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
		 @"last_activity_at_utc", @"lastActivityAt",
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
         nil];
    }
    return defaultSerializationMapping;
}

+ (NSDateFormatter *)prettyDateFormatter
{
    if (!prettyDateFormatter) {
        prettyDateFormatter = [[NSDateFormatter alloc] init];
        [prettyDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        [prettyDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [prettyDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return prettyDateFormatter;
}

+ (NSDateFormatter *)shortDateFormatter
{
    if (!shortDateFormatter) {
        shortDateFormatter = [[NSDateFormatter alloc] init];
        shortDateFormatter.dateStyle = NSDateFormatterShortStyle;
        shortDateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return shortDateFormatter;
}

+ (NSDateFormatter *)isoDateFormatter
{
    if (!isoDateFormatter) {
        isoDateFormatter = [[NSDateFormatter alloc] init];
        [isoDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        [isoDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
    }
    return isoDateFormatter;
}

// Javascript-like date format, e.g. @"Sun Mar 18 2012 17:07:20 GMT-0700 (PDT)"
+ (NSDateFormatter *)jsDateFormatter
{
    if (!jsDateFormatter) {
        jsDateFormatter = [[NSDateFormatter alloc] init];
        [jsDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        [jsDateFormatter setDateFormat:@"EEE MMM dd yyyy HH:mm:ss 'GMT'Z (zzz)"];
    }
    return jsDateFormatter;
}

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (!self.localObservedOn) {
        if (self.timeObservedAt) self.localObservedOn = self.timeObservedAt;
        else if (self.observedOn) self.localObservedOn = self.observedOn;
    }
    return self;
}

- (NSArray *)sortedObservationPhotos
{
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:YES];
    return [self.observationPhotos 
            sortedArrayUsingDescriptors:
            [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
}

- (NSArray *)sortedProjectObservations
{
    NSSortDescriptor *titleSort = [[NSSortDescriptor alloc] initWithKey:@"project.title" ascending:YES];
    return [self.projectObservations sortedArrayUsingDescriptors:
            [NSArray arrayWithObjects:titleSort, nil]];
}

- (void)setLocalObservedOn:(NSDate *)newDate
{
    [self willChangeValueForKey:@"localObservedOn"];
    [self setPrimitiveValue:newDate forKey:@"localObservedOn"];
    [self didChangeValueForKey:@"localObservedOn"];
    self.observedOnString = [Observation.jsDateFormatter stringFromDate:self.localObservedOn];
}

- (NSString *)observedOnPrettyString
{
    if (!self.localObservedOn) return @"Unknown";
    return [Observation.prettyDateFormatter stringFromDate:self.localObservedOn];
}

- (NSString *)observedOnShortString
{
    if (!self.localObservedOn) return @"?";
    NSDateFormatter *fmt = Observation.shortDateFormatter;
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSDayCalendarUnit fromDate:self.localObservedOn toDate:now options:0];
    if (comps.day == 0) {
        fmt.dateStyle = NSDateFormatterNoStyle;
        fmt.timeStyle = NSDateFormatterShortStyle;
    } else {
        fmt.dateStyle = NSDateFormatterShortStyle;
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
	return self.commentsCount.integerValue + self.identificationsCount.integerValue;
}

@end
