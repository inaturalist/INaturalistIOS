//
//  Observation.m
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/15/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Observation.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation Observation

@dynamic species_guess;
@dynamic taxon_id;
@dynamic inat_description;
@dynamic latitude;
@dynamic longitude;
@dynamic positional_accuracy;
@dynamic id;
@dynamic created_at;
@dynamic updated_at;
@dynamic local_id;
@dynamic local_created_at;
@dynamic local_updated_at;
@dynamic observed_on;
@dynamic observed_on_string;
@dynamic user_id;
@dynamic place_guess;
@dynamic id_please;
@dynamic iconic_taxon_id;
@dynamic private_latitude;
@dynamic private_longitude;
@dynamic private_positional_accuracy;
@dynamic geoprivacy;
@dynamic quality_grade;
@dynamic positioning_method;
@dynamic positioning_device;
@dynamic out_of_range;
@dynamic license;
@dynamic synced_at;

+ (NSArray *)all
{
    NSFetchRequest *request = [Observation fetchRequest];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:NO];
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"local_created_at" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
    return [Observation objectsWithFetchRequest:request];
}

+ (Observation *)stub
{
    //    NSLog(@"creating stub");
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
    o.species_guess = [speciesGuesses objectAtIndex:rand()*speciesGuesses.count];
    o.observed_on = [NSDate date];
    o.place_guess = [placeGuesses objectAtIndex:rand() % [placeGuesses count]];
    o.latitude = [NSNumber numberWithInt:rand() % 89];
    o.longitude = [NSNumber numberWithInt:rand() % 179];
    o.positional_accuracy = [NSNumber numberWithInt:rand() % 500];
    o.inat_description = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
    return o;
}

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[Observation class]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"species_guess", @"species_guess",
         @"description", @"inat_description",
         @"created_at", @"created_at",
         @"updated_at", @"updated_at",
         @"observed_on_string", @"observed_on_string",
         @"place_guess", @"place_guess",
         @"latitude", @"latitude",
         @"longitude", @"longitude",
         @"positional_accuracy", @"positional_accuracy",
         @"private_latitude", @"private_latitude",
         @"private_longitude", @"private_longitude",
         @"private_positional_accuracy", @"private_positional_accuracy",
         @"taxon_id", @"taxon_id",
         @"iconic_taxon_id", @"iconic_taxon_id",
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
         @"species_guess", @"observation[species_guess]",
         @"inat_description", @"observation[description]",
         @"observed_on_string", @"observation[observed_on_string]",
         @"place_guess", @"observation[place_guess]",
         @"latitude", @"observation[latitude]",
         @"longitude", @"observation[longitude]",
         @"positional_accuracy", @"observation[positional_accuracy]",
         @"taxon_id", @"observation[taxon_id]",
         @"iconic_taxon_id", @"observation[iconic_taxon_id]",
         nil];
    }
    return defaultSerializationMapping;
}

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    NSDate *now = [NSDate date];
    if (!self.local_created_at) [self setLocal_created_at:now];
    if (!self.observed_on) [self setObserved_on:now];
    return self;
}

- (void)setObserved_on:(NSDate *)newDate
{
    [self willChangeValueForKey:@"observed_on"];
    [self setPrimitiveValue:newDate forKey:@"observed_on"];
    [self didChangeValueForKey:@"observed_on"];
    if (!self.observed_on_string) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setTimeZone:[NSTimeZone localTimeZone]];
        [fmt setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
        self.observed_on_string = [fmt stringFromDate:self.observed_on];
    }
}

- (void)save
{
    [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)willSave
{
    if ([self changedValues] != nil) {
        NSDate *now;
        if ([self.changedValues objectForKey:@"synced_at"]) {
            now = self.synced_at;
        } else {
            now = [NSDate date];
        }
        if (self.local_updated_at) {
            NSLog(@"[self.local_updated_at timeIntervalSinceNow]: %f", [self.local_updated_at timeIntervalSinceDate:now]);
        }
        if (!self.local_updated_at || [self.local_updated_at timeIntervalSinceDate:now] < -1) {
            NSLog(@"setting local_updated_at to %@", now);
            self.local_updated_at = now;
        }
    }
    [super willSave];
}

- (void)destroy
{
    [self deleteEntity];
    [[[RKObjectManager sharedManager] objectStore] save];
}

@end
