//
//  ExploreObservationPhoto+BestAvailableURL.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/1/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreObservationPhoto+BestAvailableURL.h"

@implementation ExploreObservationPhoto (BestAvailableURL)

- (NSString *)bestAvailableUrlString {
    return [self bestAvailableUrlStringMax:ExploreObsPhotoUrlSizeLarge];
}

- (NSString *)bestAvailableUrlStringMax:(ExploreObsPhotoUrlSize)max {
    switch (max) {
        case ExploreObsPhotoUrlSizeSmall:
            if (self.smallURL) { return self.smallURL; }
            else { return nil; }
            break;
        case ExploreObsPhotoUrlSizeMedium:
            if (self.mediumURL) { return self.mediumURL; }
            else if (self.smallURL) { return self.smallURL; }
            else { return nil; }
        case ExploreObsPhotoUrlSizeLarge:
            if (self.largeURL) { return self.largeURL; }
            else if (self.mediumURL) { return self.mediumURL; }
            else if (self.smallURL) { return self.smallURL; }
            else { return nil; }
        default:
            return nil;
            break;
    }
}

@end
