//
//  GolanProjectUtil.h
//  iNaturalist
//
//  Created by Eldad Ohana on 10/8/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Project.h"

static int const kGolanWildlifeProjectID = 4527;

#ifdef DEBUG
static NSString *const kProjectServerPath = @"http://golan.carmel.coop/json/projects";
#else
static NSString *const kProjectServerPath = @"http://tatzpiteva.org.il/json/projects";
#endif

@interface GolanProjectUtil : NSObject <RKObjectLoaderDelegate>

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSArray *projectsFromServer;

- (void)signUserForGolanProject;
- (void)loadGolanProjectSettings;
/// Get the projects the user is signed up for and also received from server.
- (NSArray *)smartProjectsForObservation;
+ (Project *)golanProject;

@end
