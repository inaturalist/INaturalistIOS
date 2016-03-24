//
//  FaveVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/8/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FaveVisualization <NSObject>

- (NSString *)userName;
- (NSInteger)userId;
- (NSURL *)userIconUrl;

- (NSDate *)createdAt;

@end
