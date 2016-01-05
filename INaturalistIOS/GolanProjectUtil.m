//
//  GolanProjectUtil.m
//  iNaturalist
//
//  Created by Eldad Ohana on 10/8/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "GolanProjectUtil.h"
#import "ProjectUser.h"
#import "INaturalistAppDelegate.h"
#import <AFNetworking/AFNetworking.h>
#import "GolanProjectModel.h"

@implementation GolanProjectUtil

// ######################################################################
// Public methods
// ######################################################################
- (void)signUserForGolanProject{
    
    // Check if the user is already member of golan wildlife project.
    Project *golanProject = [[self class] golanProject];
    if(golanProject == nil){
        [self downloadUserProjects];
    }
}

- (void)loadGolanProjectSettings {
    self.projectsFromServer = @[];
    NSURL *url = [NSURL URLWithString:kProjectServerPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"text/html"]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if([JSON isKindOfClass:[NSArray class]]) {
            for(NSDictionary *project in JSON) {
                RKObjectLoaderDidLoadObjectsBlock didLoadObjectsBlock = ^(id object) {
                    if(object) {
                        GolanProjectModel *pModel = [[GolanProjectModel alloc] init];
                        pModel.projectFromServer = (Project *)object;
                        pModel.smartFlag = [[project objectForKey:@"smart_flag"] integerValue];
                        pModel.menuFlag = [[project objectForKey:@"menu_flag"] integerValue];
                        pModel.projectID = [NSNumber numberWithInt:[[project objectForKey:@"id"] intValue]];
                        self.projectsFromServer = [self.projectsFromServer arrayByAddingObject:pModel];
                    }
                };
                NSString *searchPath = [NSString stringWithFormat:@"/projects/%@",[project objectForKey:@"id"]];
                [[RKObjectManager sharedManager] loadObjectsAtResourcePath:searchPath usingBlock:^(RKObjectLoader *loader) {
                    loader.objectMapping = [Project mapping];
                    loader.onDidLoadObject = didLoadObjectsBlock;
                }];
            }
        }
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Request Failed with Error: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (NSArray *)smartProjectsForObservation {
    NSArray *projects = @[];
    // Get all the user's projects.
    NSArray *projectsForUser = [ProjectUser objectsWithPredicate:nil];
    for(GolanProjectModel *golanProject in self.projectsFromServer) {
        for(ProjectUser *project in projectsForUser) {
            if([project.projectID isEqualToNumber:golanProject.projectID]) {
                projects = [projects arrayByAddingObject:golanProject];
            }
        }
    }
    
    return projects;
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
//        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
//                                                     objectMapping:[Project mapping]
//                                                          delegate:self];
        
        RKObjectLoaderDidLoadObjectsBlock didLoadObjectsBlock = ^(NSArray *objects) {
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
        };

        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:url usingBlock:^(RKObjectLoader *loader) {
            loader.objectMapping = [Project mapping];
            loader.onDidLoadObject = didLoadObjectsBlock;
        }];
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
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
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
