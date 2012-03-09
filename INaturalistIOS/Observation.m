//
//  Observation.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/15/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Observation.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKManagedObjectMapping *defaultSerializationMapping = nil;
static NSDateFormatter *prettyDateFormatter = nil;
static NSDateFormatter *shortDateFormatter = nil;
static NSDateFormatter *isoDateFormatter = nil;

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

@synthesize sortedObservationPhotos = _sortedObservationPhotos;

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
        defaultMapping = [RKManagedObjectMapping mappingForClass:[Observation class]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"species_guess", @"speciesGuess",
         @"description", @"inatDescription",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
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
    if (!_sortedObservationPhotos) {
        NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
        NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:YES];
        self.sortedObservationPhotos = [self.observationPhotos 
                                        sortedArrayUsingDescriptors:
                                        [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
    }
    return _sortedObservationPhotos;
}

- (void)setLocalObservedOn:(NSDate *)newDate
{
    [self willChangeValueForKey:@"localObservedOn"];
    [self setPrimitiveValue:newDate forKey:@"localObservedOn"];
    [self didChangeValueForKey:@"localObservedOn"];
    self.observedOnString = [Observation.isoDateFormatter stringFromDate:self.localObservedOn];
}

- (void)willSave
{
    // sortedObservationPhotos is transient and needs to be reset
    self.sortedObservationPhotos = nil;
    [super willSave];
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

@end
