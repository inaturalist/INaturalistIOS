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

- (void)migrateObservationsToRealmProgress:(INatRealmMigrationProgressHandler)progressBlock finished:(INatRealmMigrationCompletionHandler)done {
    // migrate old observations to realm
    // do this on a background thread so we can update the UI
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Observation"];
        NSError *error = nil;
        NSArray *results = [[self coreDataMOC] executeFetchRequest:request error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                done(NO, error);
            });
        } else {
            RLMRealm *realm = [RLMRealm defaultRealm];
            CGFloat totalObservations = (CGFloat)results.count;
            NSInteger processedObservations = 0;
            for (id cdObservation in results) {
                // update the progress UI
                processedObservations += 1;
                CGFloat progress = (CGFloat)processedObservations / totalObservations;
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressBlock(progress);
                });
                
                NSDictionary *value = [ExploreObservationRealm valueForCoreDataModel:cdObservation];
                if (!value) {
                    NSError *error = [[NSError alloc] initWithDomain:@"org.inaturalist"
                                                                code:-1015
                                                            userInfo:@{ NSLocalizedDescriptionKey: @"nil value for cd observation" }];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        done(NO, error);
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        done(NO, error);
                    });
                    return;
                }
                [realm commitWriteTransaction];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                done(YES, nil);
            });
        }
    });
}

@end
