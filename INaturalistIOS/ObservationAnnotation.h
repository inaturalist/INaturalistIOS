//
//  ObservationAnnotation.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/7/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@class Observation;

@interface ObservationAnnotation : NSObject <MKAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, strong) Observation *observation;
- (id)initWithObservation:(Observation *)observation;
@end
