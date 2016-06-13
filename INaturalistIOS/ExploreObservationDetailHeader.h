//
//  ExploreObservationDetailHeader.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ExploreObservation.h"

@interface ExploreObservationDetailHeader : UIView

@property ExploreObservation *observation;

@property UILabel *commonNameLabel;
@property UILabel *scientificNameLabel;
@property UIImageView *photoImageView;

+ (CGFloat)heightForObservation:(ExploreObservation *)observation;

@end
