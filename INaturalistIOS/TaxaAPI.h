//
//  TaxaAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/25/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@interface TaxaAPI : INatAPI

- (void)taxaMatching:(NSString *)name handler:(INatAPIFetchCompletionCountHandler)done;
- (void)taxonWithId:(NSInteger)taxonId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)boundingBoxForTaxon:(NSInteger)taxon handler:(INatAPIFetchCompletionCountHandler)done;

@end
