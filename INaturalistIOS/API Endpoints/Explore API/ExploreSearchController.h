//
//  ExploreSearchController.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SearchCompletionHandler)(NSArray *results, NSError *error);

@interface ExploreSearchController : NSObject

- (void)searchForLogin:(NSString *)loginName completionHandler:(SearchCompletionHandler)handler;
- (void)searchForLocation:(NSString *)location completionHandler:(SearchCompletionHandler)handler;
- (void)searchForPerson:(NSString *)name completionHandler:(SearchCompletionHandler)handler;
- (void)searchForProject:(NSString *)project completionHandler:(SearchCompletionHandler)handler;
- (void)searchForTaxon:(NSString *)taxon completionHandler:(SearchCompletionHandler)handler;


@end
