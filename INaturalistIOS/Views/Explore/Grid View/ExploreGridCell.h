//
//  ExploreGridCell.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreObservation;

@interface ExploreGridCell : UICollectionViewCell

- (void)setObservation:(ExploreObservation *)observation;

@end
