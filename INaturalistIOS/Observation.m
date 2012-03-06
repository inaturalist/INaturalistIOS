//
//  Observation.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/15/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Observation.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation Observation

@dynamic speciesGuess;
@dynamic taxonID;
@dynamic inatDescription;
@dynamic latitude;
@dynamic longitude;
@dynamic positionalAccuracy;
@dynamic observedOn;
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

@synthesize sortedObservationPhotos = _sortedObservationPhotos;

+ (NSArray *)all
{
    NSFetchRequest *request = [self fetchRequest];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"observedOn" ascending:NO];
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
    o.observedOn = [NSDate date];
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
        defaultMapping = [RKManagedObjectMapping mappingForClass:[Observation class]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"species_guess", @"speciesGuess",
         @"description", @"inatDescription",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
//         @"observed_on", @"observedOn",
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
         nil];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKManagedObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [RKManagedObjectMapping mappingForClass:[Observation class]];
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
         nil];
    }
    return defaultSerializationMapping;
}

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (!self.observedOn) {
        if (self.timeObservedAt) self.observedOn = self.timeObservedAt;
    }
    return self;
}

- (NSArray *)sortedObservationPhotos
{
    if (!_sortedObservationPhotos) {
        NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
        NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:YES];
        self.sortedObservationPhotos = [self.observationPhotos 
                                        sortedArrayUsingDescriptors:
                                        [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
    }
    return _sortedObservationPhotos;
}

- (void)setObservedOn:(NSDate *)newDate
{
    [self willChangeValueForKey:@"observedOn"];
    [self setPrimitiveValue:newDate forKey:@"observedOn"];
    [self didChangeValueForKey:@"observedOn"];
    if (!self.observedOnString) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setTimeZone:[NSTimeZone localTimeZone]];
        [fmt setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
        self.observedOnString = [fmt stringFromDate:self.observedOn];
    }
}

- (void)willSave
{
    // sortedObservationPhotos is transient and needs to be reset
    self.sortedObservationPhotos = nil;
    [super willSave];
}

- (NSString *)observedOnPrettyString
{
    if (!self.observedOn) return @"Unknown";
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setTimeZone:[NSTimeZone localTimeZone]];
    [fmt setDateStyle:NSDateFormatterMediumStyle];
    [fmt setTimeStyle:NSDateFormatterMediumStyle];
    return [fmt stringFromDate:self.observedOn];
}

- (NSString *)observedOnShortString
{
    if (!self.observedOn) return @"?";
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSDayCalendarUnit fromDate:self.observedOn toDate:now options:0];
    if (comps.day == 0) {
        fmt.dateStyle = NSDateFormatterNoStyle;
        fmt.timeStyle = NSDateFormatterShortStyle;
    } else {
        fmt.dateStyle = NSDateFormatterShortStyle;
        fmt.timeStyle = NSDateFormatterNoStyle;
    }
    return [fmt stringFromDate:self.observedOn];
}

@end
