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

- (void)extractObjectsFromData:(NSData *)data classMapping:(Class)ClassForMapping handler:(INatAPIFetchCompletionCountHandler)done;

- (NSString *)apiBaseUrl;


- (void)requestMethod:(NSString *)method path:(NSString *)path query:(NSString *)query params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done;
- (void)put:(NSString *)path query:(NSString *)query params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done;
- (void)post:(NSString *)path query:(NSString *)query params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done;
- (void)fetch:(NSString *)path query:(NSString *)query classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done;
- (void)delete:(NSString *)path query:(NSString *)query handler:(INatAPIFetchCompletionCountHandler)done;


@end
