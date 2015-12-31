//
//  SignUserForGolanProject.m
//  iNaturalist
//
//  Created by Eldad Ohana on 10/8/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "SignUserForGolanProject.h"
#import "ProjectUser.h"
#import "INaturalistAppDelegate.h"

@implementation SignUserForGolanProject

// ######################################################################
// Public methods
// ######################################################################
- (void)signUserForGolanProject{
    
    // Check if the user is already member of golan wildlife project.
    Project *golanProject = [[self class] golanProject];
    if(golanProject == nil){
        [self downloadUserProjects];
    }
//    NSArray *projects = [ProjectUser objectsWithPredicate:nil];
//    if(projects.count){
//        BOOL found = NO;
//        for(ProjectUser *pu in projects){
//            // Check for the project id of Golan Wildlife.
//            if([pu.projectID intValue] == kGolanWildlifeProjectID){
//                found = YES;
//                break;
//            }
//        }
//        if(!found){
//            [self joinTheProject];
//        }
//        
//    }
//    else{
//        [self joinTheProject];
//    }

}

+ (Project *)golanProject{
    NSArray *projects = [ProjectUser objectsWithPredicate:nil];
    if(projects.count){
        
        for(ProjectUser *pu in projects){
            // Check for the project id of Golan Wildlife.
            if([pu.projectID intValue] == kGolanWildlifeProjectID){
                return pu.project;
            }
        }
    }
    return nil;
}

// ######################################################################
// Private methods
// ######################################################################
- (void)joinTheProject{
    NSString *url = @"/projects/search?locale=en-US&q=golan wildlife";
    
    bool netOk = [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable];
    
    if(netOk){
        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                     objectMapping:[Project mapping]
                                                          delegate:self];
    }
}

- (void)downloadUserProjects{
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [NSLocale localeForCurrentLanguage];
    NSString *path = [NSString stringWithFormat:@"/projects/user/%@.json?locale=%@-%@",
                      self.username,
                      language,
                      countryCode];
    
    RKObjectLoaderDidLoadObjectsBlock didLoadObjectsBlock = ^(NSArray *objects) {
        BOOL found = NO;
        for(ProjectUser *pu in objects){
            // Check for the project id of Golan Wildlife.
            if([pu.projectID intValue] == kGolanWildlifeProjectID){
                found = YES;
                break;
            }
        }
        if(!found)
            [self joinTheProject];
    };
    
    
    RKObjectMapping *mapping = [ProjectUser mapping];
    
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = mapping;
                                                        
                                                        loader.onDidLoadObjects = didLoadObjectsBlock;
                                                        loader.onDidLoadResponse = nil;
                                                        loader.onDidFailWithError = nil;
                                                    }];

    
    
}

// RKObjectLoaderDelegate :::::::::::::::::::::::::::::::::::::::::::::::
#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    if ([(INaturalistAppDelegate *)UIApplication.sharedApplication.delegate loggedIn] && objects.count) {
        Project *theProject = [objects objectAtIndex:0];
        // Joining the project.
        @try{
            ProjectUser *projectUser = [ProjectUser object];
            projectUser.project = theProject;
            projectUser.projectID = theProject.recordID;
            
            [[RKObjectManager sharedManager] postObject:projectUser usingBlock:^(RKObjectLoader *loader) {
                loader.delegate = self;
                loader.resourcePath = [NSString stringWithFormat:@"/projects/%d/join", theProject.recordID.intValue];
                loader.objectMapping = [ProjectUser mapping];
            }];
        }
        @catch(...){
        
        }
    }
    
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    //    just assume no results
    NSLog(@"Error");
}
// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@end
