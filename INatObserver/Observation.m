//
//  Observation.m
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Observation.h"

@implementation Observation
@synthesize createdAt, updatedAt, observedAt, speciesGuess, placeGuess, latitude, longitude, positionalAccuracy, description;

+ (NSArray *)all
{
    NSMutableArray *a = [[ObservationStore defaultStore] records];
//    [a sortUsingSelector:@selector(compareCreatedAt:)];
    [a sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[(Observation *)obj2 createdAt] compare:[(Observation *)obj1 createdAt]];
    }];
    return a;
}

+ (NSArray *)recent
{
    return [[ObservationStore defaultStore] records];
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
    Observation *o = [[Observation alloc] init];
    [o setSpeciesGuess:
     [speciesGuesses objectAtIndex:
      rand() % [speciesGuesses count]]];
    [o setObservedAt:[NSDate date]];
    [o setPlaceGuess:
     [placeGuesses objectAtIndex:
      rand() % [placeGuesses count]]];
    [o setLatitude:rand() % 89];
    [o setLongitude:rand() % 179];
    [o setPositionalAccuracy:rand() % 500];
    [o setDescription:@"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."];
    return o;
}

- (Observation *)init
{
    self = [super init];
    [self setCreatedAt:[NSDate date]];
    return self;
}

- (void)save
{   
    NSMutableArray *a = [[ObservationStore defaultStore] records];
    if (![a containsObject:self]) {
        [a addObject:self];
    }
}
@end

static ObservationStore *defaultStore = nil;
@implementation ObservationStore
@synthesize records;
+ (ObservationStore *) defaultStore
{
    if (!defaultStore) {
        defaultStore = [[ObservationStore alloc] init];
    }
    return defaultStore;
}

- (ObservationStore *)init
{
    if (defaultStore) {
        return defaultStore;
    }
    self = [super init];
    [self setRecords:[[NSMutableArray alloc] init]];
    for (int i = 0; i < 10; i++) {
        Observation *stub = [Observation stub];
//        NSLog(@"adding stub: %@", stub);
        [[self records] addObject:stub];
    }
    
    return self;
}
@end
