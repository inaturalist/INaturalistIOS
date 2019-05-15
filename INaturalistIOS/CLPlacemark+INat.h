//
//  CLPlacemark+INat.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/19/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLPlacemark (INat)

- (NSString *)inatPlaceGuess;

@end
