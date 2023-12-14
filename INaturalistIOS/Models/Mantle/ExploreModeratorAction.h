//
//  ExploreModeratorAction.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/13/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

@class ExploreUser;

@interface ExploreModeratorAction : MTLModel <MTLJSONSerializing>
@property (nonatomic, assign) NSInteger actionId;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, retain) ExploreUser *user;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *reason;

@end

