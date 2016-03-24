//
//  INatAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Project;

typedef void(^INatAPIFetchCompletionHandler)(NSArray *results, NSError *error);
typedef void(^INatAPIFetchCompletionCountHandler)(NSArray *results, NSInteger count, NSError *error);

@interface INatAPI : NSObject

- (void)fetch:(NSString *)path mapping:(RKObjectMapping *)mapping handler:(INatAPIFetchCompletionHandler)done;
- (void)fetchWithCount:(NSString *)path mapping:(RKObjectMapping *)mapping handler:(INatAPIFetchCompletionCountHandler)done;

- (NSString *)apiBaseUrl;

@end
