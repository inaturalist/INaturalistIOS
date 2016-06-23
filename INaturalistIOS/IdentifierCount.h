//
//  IdentifierCount.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class ExploreUser;

@interface IdentifierCount : MTLModel <MTLJSONSerializing>

@property ExploreUser *identifier;
@property NSInteger identificationCount;

@end
