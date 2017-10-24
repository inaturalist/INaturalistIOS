//
//  CLLocation+EXIFGPSDictionary.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/5/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "CLLocation+EXIFGPSDictionary.h"

@implementation CLLocation (EXIFGPSDictionary)

- (NSDictionary *)inat_GPSDictionary {
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];

    gps[(NSString *)kCGImagePropertyGPSLatitude] = @(fabs(self.coordinate.latitude));
    gps[(NSString *)kCGImagePropertyGPSLatitudeRef] = self.coordinate.latitude > 0 ? @"N" : @"S";
    gps[(NSString *)kCGImagePropertyGPSLongitude] = @(fabs(self.coordinate.longitude));
    gps[(NSString *)kCGImagePropertyGPSLongitudeRef] = self.coordinate.latitude > 0 ? @"W" : @"E";
    if (!isnan(self.altitude)) {
        
        gps[(NSString *)kCGImagePropertyGPSAltitude] = @(fabs(self.altitude));
        gps[(NSString *)kCGImagePropertyGPSAltitudeRef] = self.altitude > 0 ? @(0) : @(1);
    }
    gps[inat_GPSHPositioningError] = @(self.horizontalAccuracy);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    formatter.dateFormat = @"HH:mm:ss.SSSSSS";
    gps[(NSString *)kCGImagePropertyGPSTimeStamp] = [formatter stringFromDate:self.timestamp];
    formatter.dateFormat = @"yyyy:MM:dd";
    gps[(NSString *)kCGImagePropertyGPSDateStamp] = [formatter stringFromDate:self.timestamp];
    
    return [NSDictionary dictionaryWithDictionary:gps];
}

- (instancetype)inat_locationByAddingAccuracy:(CLLocationDistance)horizontalError {
    return [[CLLocation alloc] initWithCoordinate:self.coordinate
                                         altitude:self.altitude
                               horizontalAccuracy:horizontalError
                                 verticalAccuracy:self.verticalAccuracy
                                           course:self.course
                                            speed:self.speed
                                        timestamp:self.timestamp];
}

@end

NSString * const inat_GPSHPositioningError = @"HPositioningError";

