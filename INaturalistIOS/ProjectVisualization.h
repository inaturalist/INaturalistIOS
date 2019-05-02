//
//  ProjectVisualization.h
//  iNaturalistTests
//
//  Created by Alex Shepard on 10/10/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol ProjectVisualization <NSObject>

- (NSString *)title;
- (NSInteger)projectId;
- (NSInteger)locationId;
- (CLLocationDegrees)latitude;
- (CLLocationDegrees)longitude;
- (NSDate *)featuredAt;
- (NSURL *)iconUrl;
- (NSArray *)posts;
- (NSString *)inatDescription;
- (NSString *)terms;
- (NSString *)projectObservationRules;

- (BOOL)joined;

@end
