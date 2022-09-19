//
//  TaxaAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/25/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "INatAPI.h"
#import <CoreLocation/CoreLocation.h>

@class ExploreTaxon;
typedef void(^INatAPISuggestionsCompletionHandler)(NSArray *suggestions, ExploreTaxon *parent, NSError *error);

@interface TaxaAPI : INatAPI

- (void)taxaMatching:(NSString *)name handler:(INatAPIFetchCompletionCountHandler)done;
- (void)taxonWithId:(NSInteger)taxonId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)boundingBoxForTaxon:(NSInteger)taxon handler:(INatAPIFetchCompletionCountHandler)done;
- (void)suggestionsForObservationId:(NSInteger)taxonId handler:(INatAPISuggestionsCompletionHandler)done;
- (void)suggestionsForImage:(UIImage *)image location:(CLLocationCoordinate2D)coordinate date:(NSDate *)observedOn handler:(INatAPISuggestionsCompletionHandler)done;

@end
