//
//  ExploreObservationVisualizerViewController.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/4/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExploreObservationsDataSource.h"

/**
 An object that adopts the ExploreObservationVisualizer protocol
 is interested in receiving & visualizing explore observations from
 an observation data source.
 When observations change (due to updated search terms, new map 
 area, etc)  objects that adopt this protocol can get callbacks.
 
 @see ExploreObservationVisualizerViewController, ExploreObservationsDataSource
 */
@protocol ExploreObservationVisualizer
@optional
/**
 Observations have changed.
 */
- (void)observationChangedCallback;
/**
  Active Search Predicates have changed.
 */
- (void)activeSearchPredicatesChanged;
@end

/**
 This View Controller is intended for subclassing. Any subclass of 
 ExploreObservationVisualizerViewController will be setup to monitor
 an observationDataSource via KVO and callbacks will be triggered
 when the monitored observations change. Children should implement
 part of the ExploreObservationVisualizer in order to update their UI
 based on changes in the observed observations.
 
 @see ExploreObservationVisualizer
 */
@interface ExploreObservationVisualizerViewController : UIViewController <ExploreObservationVisualizer>

/**
 The datasource this view controller is visualizing observations for. This
 view controller will setup KVO on the observations property and then send
 callback on self when the observations change. Children can implement methods
 from the ExploreObservationVisualizer protocol to be update UI when the
 observed observations change. Note: This is an NSObject instead of id so
 we can KVO on it.
 
 @see ExploreObservationsDataSource, ExploreObservationVisualizer
 */
@property (weak) NSObject <ExploreObservationsDataSource> *observationDataSource;


@end

