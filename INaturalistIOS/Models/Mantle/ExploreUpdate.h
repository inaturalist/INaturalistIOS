//
//  ExploreUpdate.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "ExploreIdentification.h"
#import "ExploreComment.h"


@interface ExploreUpdate : MTLModel <MTLJSONSerializing>

@property NSDate *createdAt;
@property NSInteger updateId;
@property ExploreIdentification *identification;
@property ExploreComment *comment;
@property NSInteger resourceOwnerId;
@property NSInteger resourceId;
@property BOOL viewed;

@end
