//
//  ProjectVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/6/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, ExploreProjectType) {
    ExploreProjectTypeCollection,
    ExploreProjectTypeUmbrella,
    ExploreProjectTypeOldStyle
};

@protocol ProjectVisualization <NSObject>

- (NSString *)title;
- (NSInteger)projectId;
- (NSInteger)locationId;
- (CLLocationDegrees)latitude;
- (CLLocationDegrees)longitude;
- (NSURL *)iconUrl;
- (ExploreProjectType)type;
- (NSURL *)bannerImageUrl;
- (UIColor *)bannerColor;
- (NSString *)inatDescription;
- (NSArray *)sortedProjectObservationFields;

@end


