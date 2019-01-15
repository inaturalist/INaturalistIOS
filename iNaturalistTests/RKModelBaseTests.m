//
//  RKModelBaseTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/8/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "RKModelBaseTests.h"

@interface RKModelBaseTests ()
@property RKManagedObjectStore *objectStore;
@end

@implementation RKModelBaseTests

- (void)setUp {
    [super setUp];
    
    NSBundle *testTargetBundle = [NSBundle bundleForClass:self.class];
    [RKTestFixture setFixtureBundle:testTargetBundle];
    [RKTestFactory setUp];
    
    [RKTestFactory defineFactory:RKTestFactoryDefaultNamesManagedObjectStore withBlock:^id{
        NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
        RKManagedObjectStore *managedObjectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"inaturalistTests.sqlite"
                                                                                usingSeedDatabaseName:nil
                                                                                   managedObjectModel:managedObjectModel
                                                                                             delegate:nil];
        return managedObjectStore;
    }];
    self.objectStore = [RKTestFactory managedObjectStore];
}

- (void)tearDown {
    [RKTestFactory tearDown];
}

@end
