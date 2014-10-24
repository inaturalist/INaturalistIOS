//
//  ExploreObservationVisualizerViewController.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/4/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExploreObservationsDataSource.h"

@protocol ExploreObservationVisualizer
@optional
// visualizers will implement this to notice when observations has changed
- (void)observationChangedCallback;
- (void)observationsLimitedToLocation;
@end

@interface ExploreObservationVisualizerViewController : UIViewController <ExploreObservationVisualizer>

// NSObject instead of id so we can KVO on it
@property (weak) NSObject <ExploreObservationsDataSource> *observationDataSource;


@end

