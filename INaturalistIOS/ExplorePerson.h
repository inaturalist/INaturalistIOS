//
//  ExplorePerson.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface ExplorePerson : MTLModel <MTLJSONSerializing>

@property (assign) NSInteger personId;
@property (copy) NSString *login;
@property (copy) NSString *name;
@property (copy) NSString *userIcon;

@end
