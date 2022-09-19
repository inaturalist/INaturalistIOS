//
//  ExploreUser.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "UserVisualization.h"

@interface ExploreUser : MTLModel <MTLJSONSerializing, UserVisualization>

@property (assign) NSInteger userId;
@property (copy) NSString *login;
@property (copy) NSString *name;
@property (copy) NSURL *userIcon;
@property (copy) NSString *email;
@property (assign) NSInteger observationsCount;
@property (assign) NSInteger siteId;

// user pref stuff
@property (assign) BOOL prefersNoTracking;
@property (assign) BOOL showCommonNames;
@property (assign) BOOL showScientificNamesFirst;
@property (assign) BOOL dataTransferConsent;
@property (assign) BOOL piConsent;

@property (readonly) NSURL *userIconMedium;

@end
