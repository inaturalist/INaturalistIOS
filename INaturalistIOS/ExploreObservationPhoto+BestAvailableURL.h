//
//  ExploreObservationPhoto+BestAvailableURL.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/1/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreObservationPhoto.h"

/**
 An Explore Observation Photo URL's size. Small corresponds to -smallURL,
 medium to -mediumURL, large to -largeURL.
 */
typedef NS_ENUM(NSInteger, ExploreObsPhotoUrlSize) {
    ExploreObsPhotoUrlSizeSmall,
    ExploreObsPhotoUrlSizeMedium,
    ExploreObsPhotoUrlSizeLarge
};

@interface ExploreObservationPhoto (BestAvailableURL)

/**
 The largest URL for this photo, at or below the given max. Based on what's
 available, could be the largeURL, the mediumURL, or the smallURL. If there's no 
 smallURL, it's better to show nothing.
 @return An image URL as a string, or nil if nothing smallURL or larger was found
 */
- (NSString *)bestAvailableUrlStringMax:(ExploreObsPhotoUrlSize)max;

/**
 The largest URL for this photo. Based on what's available, could be the
 largeURL, the mediumURL, or the smallURL. If there's no smallURL, it's better 
 to show nothing.
 @return An image URL as a string, or nil if nothing smallURL or larger was found
 */
- (NSString *)bestAvailableUrlString;

@end
