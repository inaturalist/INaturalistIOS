//
//  ObservationAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ObservationAPI.h"
#import "ExploreObservation.h"
#import "ExploreUpdate.h"
#import "Analytics.h"
#import "Observation.h"

@implementation ObservationAPI

- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation from node"];
    NSString *path = [NSString stringWithFormat:@"observations/%ld", (long)identifier];
    [self fetch:path classMapping:ExploreObservation.class handler:done];
}

- (void)updatesWithHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation updates from node"];
    NSString *path = @"observations/updates?per_page=100";
    [self fetch:path classMapping:ExploreUpdate.class handler:done];
}

- (void)railsObservationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%ld", (long)identifier]
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = [Observation mapping];
                                                        loader.onDidLoadObject = ^(id object) {
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                done(@[], 0, nil);
                                                            });
                                                        };
                                                        
                                                        loader.onDidFailWithError = ^(NSError *error) {
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                done(nil, 0, error);
                                                            });
                                                        };
                                                    }];
}

- (void)seenUpdatesForObservationId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *path = [NSString stringWithFormat:@"/observations/%ld/viewed_updates", (long)identifier];
    [[RKClient sharedClient] put:path
                      usingBlock:^(RKRequest *request) {
                          request.onDidLoadResponse = ^(RKResponse *response) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  done(@[], 0, nil);
                              });
                          };
                          
                          request.onDidFailLoadWithError = ^(NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  done(nil, 0, error);
                              });
                          };
                      }];
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

@end
