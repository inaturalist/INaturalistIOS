//
//  ExploreObsFieldValue.h
//  iNaturalist
//
//  Created by Alex Shepard on 4/21/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "ExploreObsField.h"

@interface ExploreObsFieldValue : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger obsFieldValueId;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) ExploreObsField *obsField;
@property (nonatomic, copy) NSString *uuid;

@end
