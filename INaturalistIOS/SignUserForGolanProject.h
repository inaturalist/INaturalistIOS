//
//  SignUserForGolanProject.h
//  iNaturalist
//
//  Created by Eldad Ohana on 10/8/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Project.h"

static int const kGolanWildlifeProjectID = 4527;

@interface SignUserForGolanProject : NSObject <RKObjectLoaderDelegate>

@property (strong, nonatomic) NSString *username;

- (void)signUserForGolanProject;
+ (Project *)golanProject;

@end
