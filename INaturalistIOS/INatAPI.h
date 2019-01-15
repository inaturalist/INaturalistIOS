//
//  INatAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class Project;

typedef void(^INatAPIFetchCompletionCountHandler)(NSArray *results, NSInteger count, NSError *error);

@interface INatAPI : NSObject

- (void)put:(NSString *)path params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done;
- (void)post:(NSString *)path params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done;
- (void)fetch:(NSString *)path classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done;
- (void)delete:(NSString *)path handler:(INatAPIFetchCompletionCountHandler)done;

- (NSString *)apiBaseUrl;

@end
