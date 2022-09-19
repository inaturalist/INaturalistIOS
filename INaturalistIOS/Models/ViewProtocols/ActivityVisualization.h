//
//  ActivityVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/7/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ActivityVisualization <NSObject>

- (NSString *)body;

- (NSString *)userName;
- (NSInteger)userId;
- (NSURL *)userIconUrl;

- (NSDate *)createdAt;

@end
