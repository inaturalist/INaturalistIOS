//
//  ExploreObservationVisualizerViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/4/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreObservationVisualizerViewController.h"

static int KVOContext;

@interface ExploreObservationVisualizerViewController () {
    NSObject <ExploreObservationsDataSource> *_observationDataSource;
}
@end

@implementation ExploreObservationVisualizerViewController

- (void)dealloc {
    [self stopObserving:_observationDataSource forKeyPath:@"observations"];
}

#pragma mark - getter/setter

- (NSObject <ExploreObservationsDataSource> *)observationDataSource {
    return _observationDataSource;
}

- (void)setObservationDataSource:(NSObject<ExploreObservationsDataSource> *)newDataSource {
    if (_observationDataSource) {
        [self stopObserving:_observationDataSource forKeyPath:@"observations"];
    }
    
    _observationDataSource = newDataSource;
    [self startObserving:_observationDataSource forKeyPath:@"observations"];
    
    [self startObserving:_observationDataSource forKeyPath:@"activeSearchPredicates"];
}

#pragma mark - KVO

- (void)startObserving:(NSObject *)object forKeyPath:(NSString *)keyPath {
    [self.observationDataSource addObserver:self
                                 forKeyPath:keyPath
                                    options:0
                                    context:&KVOContext];
}

- (void)stopObserving:(NSObject *)object forKeyPath:(NSString *)keyPath {
    [self.observationDataSource removeObserver:self
                                    forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &KVOContext) {
        if ([object isEqual:self.observationDataSource]) {
            if ([keyPath isEqualToString:@"observations"]) {
                if ([self respondsToSelector:@selector(observationChangedCallback)])
                    [self observationChangedCallback];
            } else if ([keyPath isEqualToString:@"activeSearchPredicates"]) {
                if ([self respondsToSelector:@selector(activeSearchPredicatesChanged)]) {
                    [self activeSearchPredicatesChanged];
                }
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end
