//
//  CLPlacemark+INat.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/19/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "CLPlacemark+INat.h"

@implementation CLPlacemark (INat)

- (NSString *)inatPlaceGuess {
    NSString *placeGuess = nil;

    // start with just one of these five base location fields
    if (self.inlandWater) {
        placeGuess = self.inlandWater;
    } else if (self.ocean) {
        placeGuess = self.ocean;
    } else if (self.areasOfInterest.count > 0) {
        placeGuess = self.areasOfInterest.firstObject;
    } else if (self.thoroughfare) {
        placeGuess = self.thoroughfare;
    } else if (self.subLocality) {
        placeGuess = self.subLocality;
    }
    
    // then append locality/city, admin area/state, country (if they exist)
    if (self.locality) {
        if (placeGuess) {
            NSString *locality = [NSString stringWithFormat:@", %@", self.locality];
            placeGuess = [placeGuess stringByAppendingString:locality];
        } else {
            placeGuess = self.locality;
        }
    }
    
    if (self.administrativeArea) {
        if (placeGuess) {
            NSString *adminArea = [NSString stringWithFormat:@", %@", self.administrativeArea];
            placeGuess = [placeGuess stringByAppendingString:adminArea];
        } else {
            placeGuess = self.administrativeArea;
        }
    }

    if (self.ISOcountryCode) {
        if (placeGuess) {
            NSString *country = [NSString stringWithFormat:@", %@", self.ISOcountryCode];
            placeGuess = [placeGuess stringByAppendingString:country];
        } else {
            placeGuess = self.ISOcountryCode;
        }
    }
        
    return placeGuess;
}

@end
