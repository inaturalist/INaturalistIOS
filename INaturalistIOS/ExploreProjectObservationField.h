//
//  ExploreProjectObservationField.h
//  iNaturalistTests
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "ExploreObservationField.h"

NS_ASSUME_NONNULL_BEGIN

@interface ExploreProjectObservationField : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger projectObservationFieldId;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, assign) BOOL required;

@property (retain) ExploreObservationField *observationField;


@end

NS_ASSUME_NONNULL_END
