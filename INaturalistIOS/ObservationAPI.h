//
//  ObservationAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@interface ObservationAPI : INatAPI

- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done;
- (void)railsObservationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done;
- (void)updatesWithHandler:(INatAPIFetchCompletionCountHandler)done;
- (void)seenUpdatesForObservationId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done;
- (void)topObserversForTaxaIds:(NSArray *)taxaIds handler:(INatAPIFetchCompletionCountHandler)done;
- (void)topIdentifiersForTaxaIds:(NSArray *)taxaIds handler:(INatAPIFetchCompletionCountHandler)done;

@end
