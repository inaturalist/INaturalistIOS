//
//  IdentifierCount.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ExplorePerson;

@interface IdentifierCount : NSObject

@property NSString *identifierIconUrl;
@property NSString *identifierName;
@property NSInteger identifierId;
@property NSInteger identificationCount;

@end
