//
//  Activity.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/20/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "INatModel.h"

#import "ActivityVisualization.h"

@class User, Observation;

@interface Activity : INatModel <ActivityVisualization>

@property (nonatomic, retain) NSString *body;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Observation *observation;
@property (nonatomic, retain) NSDate * createdAt;
@end
