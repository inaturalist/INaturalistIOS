//
//  ExploreGuideRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/15/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "RLMObject.h"
#import "ExploreGuide.h"
#import "Guide.h"

@interface ExploreGuideRealm : RLMObject

@property NSInteger guideId;
@property NSString *title;
@property NSString *desc;
@property NSDate *createdAt;
@property NSDate *updatedAt;
@property NSString *iconUrlString;
@property NSInteger taxonId;
@property CLLocationDegrees latitude;
@property CLLocationDegrees longitude;
@property NSDate *ngzDownloadedAt;
@property NSString *userLogin;

@property (readonly) NSURL *iconURL;

- (instancetype)initWithMantleModel:(ExploreGuide *)model;

+ (NSDictionary *)valueForMantleModel:(ExploreGuide *)model;
+ (NSDictionary *)valueForCoreDataModel:(Guide *)model;

@end
