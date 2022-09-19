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
#import "Analytics.h"

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

- (void)migrateObservationsToRealmProgress:(INatRealmMigrationProgressHandler)progressBlock finished:(INatRealmMigrationCompletionHandler)done {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Observation"];
    
    NSError *error = nil;
    NSArray *results = [[self coreDataMOC] executeFetchRequest:request error:&error];
    
    NSMutableArray *observationsForRealm = [NSMutableArray array];
    
    [Analytics.sharedClient debugLog:@"Migration: Begin"];
    
    if (error) {
        [Analytics.sharedClient debugLog:@"Migration: Failed - cannot get MOC"];
        [Analytics.sharedClient debugError:error];
        done(NO, @"", error);
    } else {
        [Analytics.sharedClient debugLog:[NSString stringWithFormat:@"Migration: %ld to migrate", (long)results.count]];

        for (id cdObservation in results) {
            // debug, trigger fault to fire
            [cdObservation willAccessValueForKey:nil];
                                    
            if ([cdObservation respondsToSelector:@selector(uuid)]) {
                NSString *uuid = [cdObservation performSelector:@selector(uuid)];
                if (!uuid) {
                    // can't do anything with observations without uuids
                    continue;
                }
            }
                        
            NSError *error = nil;
            NSDictionary *value = [ExploreObservationRealm valueForCoreDataModel:cdObservation error:&error];
            
            if (!value) {
                if (error) {
                    done(NO, nil, error);
                    return;
                } else {
                    // can't do anything with an empty observation
                    // should be safe to skip
                    continue;
                }
            }
            
            ExploreObservationRealm *o = [[ExploreObservationRealm alloc] initWithValue:value];
            
            if (!o) {
                NSError *error = [[NSError alloc] initWithDomain:@"org.inaturalist"
                                                            code:-1016
                                                        userInfo:@{ NSLocalizedDescriptionKey: @"value failed to insert to realm" }];
                [Analytics.sharedClient debugLog:@"Migration: Failed - value failed to insert to realm"];
                [Analytics.sharedClient debugError:error];
                done(NO, nil, error);
                return;
            }
            
            [observationsForRealm addObject:o];
        }
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [realm addOrUpdateObjects:observationsForRealm];
        [realm commitWriteTransaction];
        
        done(YES, nil, nil);
    }
}

@end
