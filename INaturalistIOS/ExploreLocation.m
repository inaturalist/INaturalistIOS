//
//  ExploreLocation.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/1/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

@import MapKit;

#import "ExploreLocation.h"

@implementation ExploreLocation

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"locationId": @"id",
		@"type": @"place_type",
		@"name": @"name",
		@"location": @"location",
		@"adminLevel": @"admin_level",
	};
}


+ (NSValueTransformer *)locationJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(NSString *locationCoordinateString) {
    	NSArray *c = [locationCoordinateString componentsSeparatedByString:@","];
    	CLLocationCoordinate2D coords = CLLocationCoordinate2DMake([((NSString *)c[0]) floatValue], [((NSString *)c[1]) floatValue]);
    	return [NSValue valueWithMKCoordinate:coords];
    }];
}


@end
