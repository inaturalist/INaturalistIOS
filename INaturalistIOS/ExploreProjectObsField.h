//
//  ExploreProjectObsField.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

@class ExploreObsField;

@interface ExploreProjectObsField : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) BOOL required;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, assign) NSInteger projectObsFieldId;
@property (nonatomic) ExploreObsField *obsField;

@end
