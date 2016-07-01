//
//  ExploreUser.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface ExploreUser : MTLModel <MTLJSONSerializing>

@property (assign) NSInteger userId;
@property (copy) NSString *login;
@property (copy) NSString *name;
@property (copy) NSURL *userIcon;

@end
