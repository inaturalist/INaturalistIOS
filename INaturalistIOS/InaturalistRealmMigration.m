//
//  InaturalistRealmMigration.m
//  iNaturalist
//
//  Created by Alex Shepard on 4/12/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

@import CoreData;
@import Realm;


#import "InaturalistRealmMigration.h"
#import "ExploreTaxonRealm.h"
#import "ExploreObservationRealm.h"

@implementation InaturalistRealmMigration

- (NSManagedObjectContext *)coreDataMOC {
    NSError *error = nil;
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *storePath = [docDir stringByAppendingPathComponent:@"inaturalist.sqlite"];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
    NSString *momPath = [[[NSBundle mainBundle] pathsForResourcesOfType:@"momd"
                                                            inDirectory:nil] firstObject];
    NSURL *momURL = [NSURL fileURLWithPath:momPath];
    
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES};
    
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeURL
                                 options:options
                                   error:&error]) {
        [NSException raise:@"Failed to open database" format:@"%@", error.localizedDescription];
    }
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:psc];
    
    return moc;
}

- (void)migrateTaxaToRealm {
    // migrate old core data taxon objects to realm
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Taxon"];
    
    NSError *error = nil;
    NSArray *results = [[self coreDataMOC] executeFetchRequest:request error:&error];
    RLMRealm *realm = [RLMRealm defaultRealm];
    for (id cdTaxon in results) {
        
        NSDictionary *value = [ExploreTaxonRealm valueForCoreDataModel:cdTaxon];
        [realm beginWriteTransaction];
        [ExploreTaxonRealm createOrUpdateInRealm:realm
                                       withValue:value];
        [realm commitWriteTransaction];
    }
    
    if (!results) {
        NSLog(@"Error fetching Taxon objects: %@\n%@", [error localizedDescription], [error userInfo]);
        // not the end of the world if we can't migrate a core data taxon
    }
}

- (void)migrateObservationsToRealm {
    // migrate old observations to realm
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Observation"];
    
    NSError *error = nil;
    NSArray *results = [[self coreDataMOC] executeFetchRequest:request error:&error];
    RLMRealm *realm = [RLMRealm defaultRealm];
    for (id cdObservation in results) {
        NSDictionary *value = [ExploreObservationRealm valueForCoreDataModel:cdObservation];
        [realm beginWriteTransaction];
        [ExploreObservationRealm createOrUpdateInRealm:realm
                                             withValue:value];
        [realm commitWriteTransaction];
    }
    
    if (!results) {
        if (error) {
            NSLog(@"Error fetching Observation objects: %@\n%@", [error localizedDescription], [error userInfo]);
            // TOOD: what should we do here?
        }
    }
}


@end
