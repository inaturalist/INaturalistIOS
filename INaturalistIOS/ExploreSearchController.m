//
//  ExploreSearchController.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>

#import "ExploreSearchController.h"
#import "Taxon.h"
#import "ExploreMappingProvider.h"
#import "NSLocale+INaturalist.h"

@implementation ExploreSearchController

- (void)searchForTaxon:(NSString *)taxon completionHandler:(SearchCompletionHandler)handler {
    NSString *pathPattern = @"/taxa/search.json";
    NSString *queryBase = @"?per_page=25&q=%@";
    NSString *query = [NSString stringWithFormat:queryBase, taxon];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    
    [self searchForPath:path mapping:[Taxon mapping] completionHandler:handler];
}

- (void)searchForPerson:(NSString *)name completionHandler:(SearchCompletionHandler)handler {
    NSString *pathPattern = @"/people/search.json";
    NSString *queryBase = @"?per_page=25&q=%@";
    NSString *query = [NSString stringWithFormat:queryBase, name];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    
    [self searchForPath:path mapping:[ExploreMappingProvider personMapping] completionHandler:handler];
}

- (void)searchForLocation:(NSString *)location completionHandler:(SearchCompletionHandler)handler {
    NSString *pathPattern = @"/places/search.json";
    NSString *queryBase = @"?per_page=25&with_geom=true&q=%@";
    NSString *query = [NSString stringWithFormat:queryBase, location];
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];

    [self searchForPath:path mapping:[ExploreMappingProvider locationMapping] completionHandler:handler];
}

- (void)searchForProject:(NSString *)project completionHandler:(SearchCompletionHandler)handler {
    NSString *pathPattern = @"/projects/search.json";
    NSString *queryBase = @"?per_page=25&q=%@";
    NSString *query = [NSString stringWithFormat:queryBase, project];
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    
    [self searchForPath:path mapping:[ExploreMappingProvider projectMapping] completionHandler:handler];
}

- (void)searchForLogin:(NSString *)loginName completionHandler:(SearchCompletionHandler)handler {
    NSString *pathPattern = [NSString stringWithFormat:@"/people/%@.json", loginName];
    NSString *query = @"?per_page=1";
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    
    [self searchForPath:path mapping:[ExploreMappingProvider personMapping] completionHandler:handler];
}

- (void)searchForPath:(NSString *)path mapping:(RKObjectMapping *)mapping completionHandler:(SearchCompletionHandler)handler {
    
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
    if (localeString && ![localeString isEqualToString:@""]) {
        NSString *localeQueryComponent = [NSString stringWithFormat:@"&locale=%@", localeString];
        path = [path stringByAppendingString:localeQueryComponent];
    }

    [[Analytics sharedClient] debugLog:@"Network - Explore search"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path usingBlock:^(RKObjectLoader *loader) {
        
        // can't infer search mappings via keypath
        loader.objectMapping = mapping;
        
        loader.onDidLoadObjects = ^(NSArray *array) {
            handler(array, nil);
        };
        
        loader.onDidFailWithError = ^(NSError *err) {
            handler(nil, err);
        };
        
        loader.onDidFailLoadWithError = ^(NSError *err) {
            handler(nil, err);
        };
    }];
}

@end
