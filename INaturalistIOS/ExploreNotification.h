//
//  ExplroeNotification.h
//  iNaturalist
//
//  Created by Alex Shepard on 9/7/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

@class ExploreComment;
@class ExploreIdentification;

@interface ExploreNotification : MTLModel

@property ExploreComment *comment;
@property ExploreIdentification *identification;

@end
