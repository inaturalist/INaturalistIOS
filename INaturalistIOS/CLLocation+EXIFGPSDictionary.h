//
//  CLLocation+EXIFGPSDictionary.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/5/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

extern NSString * const inat_GPSHPositioningError;

@interface CLLocation (EXIFGPSDictionary)

- (NSDictionary *)inat_GPSDictionary;
- (instancetype)inat_locationByAddingAccuracy:(CLLocationDistance)horizontalError;

@end
