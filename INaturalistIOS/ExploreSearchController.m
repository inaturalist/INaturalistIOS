//
//  ExploreSearchController.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>

#import "ExploreSearchController.h"
#import "NSLocale+INaturalist.h"
#import "Analytics.h"
#import "ExploreTaxon.h"
#import "ExploreProject.h"
#import "ExploreUser.h"
#import "ExploreLocation.h"
#import "INatAPI.h"
#import "NSLocale+INaturalist.h"

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

- (NSString *)searchPathForQuery:(NSString *)userQuery inCategory:(NSString *)category {
	NSString *pathPattern = [NSString stringWithFormat:@"%@/autocomplete", category];
    NSString *queryBase = @"?per_page=25&q=%@";
    NSString *query = [NSString stringWithFormat:queryBase, userQuery];
    
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
	if (localeString && ![localeString isEqualToString:@""]) {
		query = [query stringByAppendingString:[NSString stringWithFormat:@"&locale=%@", localeString]];
	}
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
	return path;
}

- (void)performSearchForPath:(NSString *)path classMapping:(Class)klass handler:(SearchCompletionHandler)handler {
	[self.api fetch:path classMapping:klass handler:^(NSArray *results, NSInteger count, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			handler(results, error);
		});
	}];
}

- (void)searchForTaxon:(NSString *)taxon completionHandler:(SearchCompletionHandler)handler {
    NSString *path = [self searchPathForQuery:taxon inCategory:@"taxa"];
    [self performSearchForPath:path classMapping:ExploreTaxon.class handler:handler];
}

- (void)searchForPerson:(NSString *)name completionHandler:(SearchCompletionHandler)handler {
	NSString *path = [self searchPathForQuery:name inCategory:@"users"];
	[self performSearchForPath:path classMapping:ExploreUser.class handler:handler];
}

- (void)searchForLocation:(NSString *)location completionHandler:(SearchCompletionHandler)handler {
	NSString *path = [self searchPathForQuery:location inCategory:@"places"];
	[self performSearchForPath:path classMapping:ExploreLocation.class handler:handler];
}

- (void)searchForProject:(NSString *)project completionHandler:(SearchCompletionHandler)handler {
	NSString *path = [self searchPathForQuery:project inCategory:@"projects"];
	[self performSearchForPath:path classMapping:ExploreProject.class handler:handler];
}

- (void)searchForLogin:(NSString *)loginName completionHandler:(SearchCompletionHandler)handler {
	[self searchForPerson:loginName completionHandler:handler];
}

@end
