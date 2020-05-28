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
    // migrate old observations to realm
    // do this on a background thread so we can update the UI
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Observation"];
        NSError *error = nil;
        NSArray *results = [[self coreDataMOC] executeFetchRequest:request error:&error];
        
        [Analytics.sharedClient debugLog:@"Migration: Begin"];
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [Analytics.sharedClient debugLog:@"Migration: Failed - cannot get MOC"];
                [Analytics.sharedClient debugError:error];
                done(NO, @"", error);
            });
        } else {
            RLMRealm *realm = [RLMRealm defaultRealm];
            CGFloat totalObservations = (CGFloat)results.count;
            NSInteger processedObservations = 0;
            [Analytics.sharedClient debugLog:[NSString stringWithFormat:@"Migration: %ld to migrate", (long)totalObservations]];

            for (id cdObservation in results) {
                // update the progress UI
                processedObservations += 1;
                CGFloat progress = (CGFloat)processedObservations / totalObservations;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [Analytics.sharedClient debugLog:@"Migration: updating progress"];
                    progressBlock(progress);
                });
                
                NSDictionary *value = [ExploreObservationRealm valueForCoreDataModel:cdObservation];
                if (!value) {
                    NSError *error = [[NSError alloc] initWithDomain:@"org.inaturalist"
                                                                code:-1015
                                                            userInfo:@{ NSLocalizedDescriptionKey: @"nil value for cd observation" }];
                    
                    [Analytics.sharedClient debugLog:@"Migration: Failed - nil value for cd observation"];
                    [Analytics.sharedClient debugError:error];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *report = [NSString stringWithFormat:@"processed %ld of %ld, then bailed, got nil value for cd observation",
                                            (long)processedObservations, (long)totalObservations];
                        done(NO, report, error);
                    });
                    return;
                }
                [realm beginWriteTransaction];
                ExploreObservationRealm *o = [ExploreObservationRealm createOrUpdateInRealm:realm
                                                                                  withValue:value];
                if (!o) {
                    NSError *error = [[NSError alloc] initWithDomain:@"org.inaturalist"
                                                                code:-1016
                                                            userInfo:@{ NSLocalizedDescriptionKey: @"value failed to insert to realm" }];
                    
                    [Analytics.sharedClient debugLog:@"Migration: Failed - value failed to insert to realm"];
                    [Analytics.sharedClient debugError:error];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *report = [NSString stringWithFormat:@"processed %ld of %ld, then bailed, value failed to insert to realm",
                                            (long)processedObservations, (long)totalObservations];
                        done(NO, report, error);
                    });
                    return;
                }
                
                
                [Analytics.sharedClient debugLog:[NSString stringWithFormat:@"Migration: completed %ld of %ld",
                                                  processedObservations, (long)totalObservations]];

                [realm commitWriteTransaction];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *report;
                if (totalObservations == 0 && processedObservations == 0) {
                    [Analytics.sharedClient debugLog:@"Migration: Empty Migration"];
                    report = @"Nothing to migrate.";
                }  else {
                    [Analytics.sharedClient debugLog:@"Migration: Finished"];
                    report =  [NSString stringWithFormat:@"processed %ld of %ld, completed successfully",
                               (long)processedObservations, (long)totalObservations];;
                }
                
                done(YES, report, nil);
            });
        }
    });
}

@end
