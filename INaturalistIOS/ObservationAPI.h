//
//  ObservationAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@class Observation;

@interface ObservationAPI : INatAPI

- (void)observationsForUserId:(NSInteger)userId count:(NSInteger)count handler:(INatAPIFetchCompletionCountHandler)done;
- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done;
- (void)updatesWithHandler:(INatAPIFetchCompletionCountHandler)done;
- (void)seenUpdatesForObservationId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done;
- (void)topObserversForTaxaIds:(NSArray *)taxaIds handler:(INatAPIFetchCompletionCountHandler)done;
- (void)topIdentifiersForTaxaIds:(NSArray *)taxaIds handler:(INatAPIFetchCompletionCountHandler)done;
- (void)faveObservationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done;
- (void)unfaveObservationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done;

- (void)postObservation:(Observation *)observation handler:(INatAPIFetchCompletionCountHandler)done;
- (void)fetchDeletedObservationsSinceDate:(NSDate *)sinceDate handler:(INatAPIFetchCompletionCountHandler)done;

@end
