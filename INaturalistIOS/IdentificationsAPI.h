//
//  IdentificationsAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/5/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@interface IdentificationsAPI : INatAPI

- (void)addIdentificationTaxonId:(NSInteger)taxonId
                   observationId:(NSInteger)obsId
                            body:(NSString *)body
                          vision:(BOOL)withVision
                         handler:(INatAPIFetchCompletionCountHandler)done;

- (void)withdrawIdentification:(NSInteger)identfiicationId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)restoreIdentification:(NSInteger)identificationId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)updateIdentification:(NSInteger)identificationId newBody:(NSString *)body handler:(INatAPIFetchCompletionCountHandler)done;

@end
