//
//  ExploreGuide.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/13/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Mantle/Mantle.h>

@class ExploreTaxon;

@interface ExploreGuide : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger guideId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSDate *createdAt;
@property (nonatomic, copy) NSDate *updatedAt;
@property (nonatomic, copy) NSURL *iconURL;
@property (nonatomic, assign) NSInteger taxonId;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, copy) NSString *userLogin;

@end
