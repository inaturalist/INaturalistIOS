//
//  IdentificationsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/5/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "IdentificationsAPI.h"
#import "Analytics.h"

@implementation IdentificationsAPI

- (void)addIdentificationTaxonId:(NSInteger)taxonId observationId:(NSInteger)obsId body:(NSString *)body vision:(BOOL)withVision handler:(INatAPIFetchCompletionCountHandler)done {
    
    [[Analytics sharedClient] debugLog:@"Network - post identification via node"];
    NSString *path = @"identifications";
    NSDictionary *identification = @{
                                     @"observation_id": @(obsId),
                                     @"taxon_id": @(taxonId),
                                     @"current": @(YES),
                                     @"vision": @(withVision),
                                     };
    if (body) {
        // make mutable to add body
        NSMutableDictionary *mutableIdentification = [identification mutableCopy];
        mutableIdentification[@"body"] = body;
        // make immutable
        identification = [NSDictionary dictionaryWithDictionary:mutableIdentification];
    }
    
    NSDictionary *params = @{ @"identification": identification };
    [self post:path params:params classMapping:nil handler:done];
}

- (void)withdrawIdentification:(NSInteger)identfiicationId handler:(INatAPIFetchCompletionCountHandler)done {
    NSDictionary *params = @{ @"identification": @{ @"current": @(NO), } };
    [self updateIdentification:identfiicationId params:params handler:done];
}

- (void)restoreIdentification:(NSInteger)identificationId handler:(INatAPIFetchCompletionCountHandler)done {
    NSDictionary *params = @{ @"identification": @{ @"current": @(YES) } };
    [self updateIdentification:identificationId params:params handler:done];
}

- (void)updateIdentification:(NSInteger)identificationId newBody:(NSString *)body handler:(INatAPIFetchCompletionCountHandler)done {
    NSDictionary *params = @{ @"identification": @{ @"body": body, } };
    [self updateIdentification:identificationId params:params handler:done];
}



- (void)updateIdentification:(NSInteger)identificationId params:(NSDictionary *)params handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - put/update id body via node"];
    NSString *path = [NSString stringWithFormat:@"identification/%ld", (long)identificationId];
    [self put:path params:params classMapping:nil handler:done];
}


@end
