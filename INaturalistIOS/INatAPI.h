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

- (void)fetch:(NSString *)path classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done;
- (NSString *)apiBaseUrl;

@end
