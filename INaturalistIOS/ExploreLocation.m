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
		@"name": @"display_name",
		@"location": @"location",
		@"adminLevel": @"admin_level",
        @"boundingBoxOrigin": @"bounding_box_geojson",
        @"boundingBoxCGSize": @"bounding_box_geojson",
	};
}

-(void)setNilValueForKey:(NSString *)key {
    [self setValue:@0 forKey:key];
}

+ (NSValueTransformer *)locationJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(NSString *locationCoordinateString) {
    	NSArray *c = [locationCoordinateString componentsSeparatedByString:@","];
    	CLLocationCoordinate2D coords = CLLocationCoordinate2DMake([((NSString *)c[0]) floatValue], [((NSString *)c[1]) floatValue]);
    	return [NSValue valueWithMKCoordinate:coords];
    }];
}

+ (NSValueTransformer *)boundingBoxOriginJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(id box) {
        if (box) {
            MKMapRect mapRect = [ExploreLocation mapRectForBoundingBox:box];
            CLLocationCoordinate2D origin = MKCoordinateForMapPoint(mapRect.origin);
            return [NSValue valueWithMKCoordinate:origin];
        } else {
            return [NSValue valueWithMKCoordinate:kCLLocationCoordinate2DInvalid];
        }
    }];
}

+ (NSValueTransformer *)boundingBoxCGSizeJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(id box) {
        if (box) {
            MKMapRect mapRect = [ExploreLocation mapRectForBoundingBox:box];
            return [NSValue valueWithCGSize:CGSizeMake(mapRect.size.width, mapRect.size.height)];
        } else {
            return [NSValue valueWithCGSize:CGSizeMake(0, 0)];
        }
    }];
}

+ (MKMapRect)mapRectForBoundingBox:(id)box {
    NSArray *arrayBox = [[box valueForKey:@"coordinates"] firstObject];
    
    CLLocationCoordinate2D first = CLLocationCoordinate2DMake([[arrayBox[0] lastObject] floatValue],
                                                              [[arrayBox[0] firstObject] floatValue]);
    
    CLLocationCoordinate2D third = CLLocationCoordinate2DMake([[arrayBox[2] lastObject] floatValue],
                                                              [[arrayBox[2] firstObject] floatValue]);
    
    MKMapPoint p1 = MKMapPointForCoordinate(first);
    MKMapPoint p2 = MKMapPointForCoordinate(third);
    
    return MKMapRectMake(fmin(p1.x,p2.x), fmin(p1.y,p2.y), fabs(p1.x-p2.x), fabs(p1.y-p2.y));
}

- (MKMapRect)boundingBox {
    if (CLLocationCoordinate2DIsValid(self.boundingBoxOrigin)) {
        MKMapPoint origin = MKMapPointForCoordinate(self.boundingBoxOrigin);
        MKMapSize size = MKMapSizeMake(self.boundingBoxCGSize.width, self.boundingBoxCGSize.height);
        return MKMapRectMake(origin.x, origin.y, size.width, size.height);
    } else {
        return MKMapRectNull;
    }
}

@end





