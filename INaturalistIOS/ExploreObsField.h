//
//  ExploreObsField.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

typedef NS_ENUM(NSInteger, ExploreObsFieldDataType) {
    ExploreObsFieldDataTypeText,
    ExploreObsFieldDataTypeNumeric,
    ExploreObsFieldDataTypeDate,
    ExploreObsFieldDataTypeTime,
    ExploreObsFieldDataTypeDateTime,
    ExploreObsFieldDataTypeTaxon,
    ExploreObsFieldDataTypeDna
};

@interface ExploreObsField : MTLModel <MTLJSONSerializing>

@property (copy) NSArray *allowedValues;
@property (copy) NSString *name;
@property (copy) NSString *inatDescription;
@property (assign) NSInteger obsFieldId;
@property (assign) ExploreObsFieldDataType dataType;

@end
