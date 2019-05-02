//
//  ExploreObservationField.h
//  iNaturalistTests
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExploreObservationField : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger fieldId;
@property (nonatomic, copy) NSArray *allowedValues;
@property (nonatomic, copy) NSString *dataType;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *inatDescription;

@end

NS_ASSUME_NONNULL_END
