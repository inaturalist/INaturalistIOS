//
//  ObservationAnnotation.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/7/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationAnnotation.h"
#import "Observation.h"

@implementation ObservationAnnotation
@synthesize coordinate = _coordinate;
@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize observation = _observation;

- (id)initWithObservation:(Observation *)observation
{
    self = [super init];
    if (self) {
        self.observation = observation;
        self.title = observation.speciesGuess && observation.speciesGuess.length > 0 ? observation.speciesGuess : NSLocalizedString(@"Something...",nil);
        self.subtitle = observation.observedOnPrettyString;
        self.coordinate = CLLocationCoordinate2DMake([observation.visibleLatitude doubleValue], [observation.visibleLongitude doubleValue]);
    }
    return self;
}
@end
