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
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic observedOn;
@dynamic observedOnString;
@dynamic userID;
@dynamic placeGuess;
@dynamic idPlease;
@dynamic iconicTaxonID;
@dynamic privateLatitude;
@dynamic privateLongitude;
@dynamic privatePositionalAccuracy;
@dynamic geoprivacy;
@dynamic qualityGrade;
@dynamic positioningMethod;
@dynamic positioningDevice;
@dynamic outOfRange;
@dynamic license;
@dynamic syncedAt;
@dynamic observationPhotos;

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
    o.speciesGuess = [speciesGuesses objectAtIndex:rand()*speciesGuesses.count];
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
         @"speciesGuess", @"species_guess",
         @"description", @"inat_description",
         @"createdAt", @"created_at",
         @"updatedAt", @"updated_at",
         @"observedOnString", @"observed_on_string",
         @"placeGuess", @"place_guess",
         @"latitude", @"latitude",
         @"longitude", @"longitude",
         @"positional_accuracy", @"positional_accuracy",
         @"privateLatitude", @"private_latitude",
         @"privateLongitude", @"private_longitude",
         @"privatePositional_accuracy", @"private_positional_accuracy",
         @"taxonID", @"taxon_id",
         @"iconicTaxonID", @"iconic_taxon_id",
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
    NSDate *now = [NSDate date];
    if (!self.observedOn) [self setObservedOn:now];
    return self;
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

@end
