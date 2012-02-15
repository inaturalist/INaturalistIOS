//
//  Observation.h
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Observation : NSObject

@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSDate *observedAt;
@property (nonatomic, strong) NSString *speciesGuess;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *placeGuess;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) int positionalAccuracy;

# pragma mark INRecord methods?
+ (NSArray *)all;
+ (Observation *)find:(int)id;
+ (NSArray *)recent;
+ (NSArray *)recent:(int)limit;
+ (void)sync;
+ (Observation *)stub;
- (void)save;
@end

// this is a stub to just keep a bunch of observaitons in memory while developing.  
// Future iterations should use a more sophisticated store
@interface ObservationStore : NSObject
@property (nonatomic, strong) NSMutableArray *records;
+ (ObservationStore *) defaultStore;
@end
