//
//  ExploreListTableViewCell.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/6/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreObservation;

@interface ExploreListTableViewCell : UITableViewCell

- (void)setObservation:(ExploreObservation *)observation;

@end
