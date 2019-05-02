//
//  ExploreObservationFieldValue.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExploreObservationFieldValue : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger fieldId;
@property (copy) NSString *uuid;
@property (copy) NSString *value;

@end

NS_ASSUME_NONNULL_END
