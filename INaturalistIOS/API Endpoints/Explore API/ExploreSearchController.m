//
//  ExploreSearchController.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreSearchController.h"
#import "ExploreTaxon.h"
#import "ExploreProject.h"
#import "ExploreUser.h"
#import "ExploreLocation.h"
#import "INatAPI.h"

@interface ExploreSearchController ()
@property (readonly) INatAPI *api;
@end

@implementation ExploreSearchController

- (INatAPI *)api {
    static INatAPI *_api;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[INatAPI alloc] init];
    });
    return _api;
}

- (void)performSearchForPath:(NSString *)path query:(NSString *)query classMapping:(Class)klass handler:(SearchCompletionHandler)handler {
    [self.api fetch:path query:query classMapping:klass handler:^(NSArray *results, NSInteger count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(results, error);
        });
    }];
}

- (void)searchForTaxon:(NSString *)searchString completionHandler:(SearchCompletionHandler)handler {
    NSString *path = @"/v1/taxa/autocomplete";
    NSString *query = [NSString stringWithFormat:@"per_page=25&q=%@", searchString];
    [self performSearchForPath:path query:query classMapping:ExploreTaxon.class handler:handler];
}

- (void)searchForPerson:(NSString *)searchString completionHandler:(SearchCompletionHandler)handler {
    NSString *path = @"/v1/users/autocomplete";
    NSString *query = [NSString stringWithFormat:@"per_page=25&q=%@", searchString];
    [self performSearchForPath:path query:query classMapping:ExploreUser.class handler:handler];
}

- (void)searchForLocation:(NSString *)searchString completionHandler:(SearchCompletionHandler)handler {
    NSString *path = @"/v1/places/autocomplete";
    NSString *query = [NSString stringWithFormat:@"per_page=25&q=%@", searchString];
    [self performSearchForPath:path query:query classMapping:ExploreLocation.class handler:handler];
}

- (void)searchForProject:(NSString *)searchString completionHandler:(SearchCompletionHandler)handler {
    NSString *path = @"/v1/projects/autocomplete";
    NSString *query = [NSString stringWithFormat:@"per_page=25&q=%@", searchString];
    [self performSearchForPath:path query:query classMapping:ExploreProject.class handler:handler];
}

- (void)searchForLogin:(NSString *)loginName completionHandler:(SearchCompletionHandler)handler {
    [self searchForPerson:loginName completionHandler:handler];
}

@end
