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
    
    // migration report will be emailed to the user
    NSMutableString *migrationReport = [NSMutableString string];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Observation"];
    
    NSError *error = nil;
    NSArray *results = [[self coreDataMOC] executeFetchRequest:request error:&error];
    
    [Analytics.sharedClient debugLog:@"Migration: Begin"];
    [migrationReport appendString:@"Migration: Begin\n"];
    
    if (error) {
        [Analytics.sharedClient debugLog:@"Migration: Failed - cannot get MOC"];
        [migrationReport appendString:@"Migration: Failed - cannot get MOC\n"];
        [Analytics.sharedClient debugError:error];
        done(NO, @"", error);
    } else {
        RLMRealm *realm = [RLMRealm defaultRealm];
        CGFloat totalObservations = (CGFloat)results.count;
        NSInteger processedObservations = 0;
        NSInteger skippedObservations = 0;
        [Analytics.sharedClient debugLog:[NSString stringWithFormat:@"Migration: %ld to migrate", (long)totalObservations]];
        [migrationReport appendFormat:@"Migration: %ld to migrate\n", (long)totalObservations];
        
        for (id cdObservation in results) {
            [migrationReport appendString:@"\n\n"];
            [migrationReport appendFormat:@"Migration: working on %@\n", [cdObservation description]];
            if ([cdObservation respondsToSelector:@selector(uploadableRepresentation)]) {
                NSDictionary *uploadableRepresentation = [cdObservation performSelector:@selector(uploadableRepresentation)];
                [migrationReport appendFormat:@"Migration: uploadable representation is %@\n", uploadableRepresentation];
            } else {
                [migrationReport appendString:@"Migration: no uploadable representation"];
            }
            
            if ([cdObservation respondsToSelector:@selector(recordID)]) {
                NSNumber *recordId = [cdObservation performSelector:@selector(recordID)];
                [migrationReport appendFormat:@"Migration: record id is %@\n", recordId];
            } else {
                [migrationReport appendString:@"Migration: no record id"];
            }
            
            if ([cdObservation respondsToSelector:@selector(uuid)]) {
                NSString *uuid = [cdObservation performSelector:@selector(uuid)];
                [migrationReport appendFormat:@"Migration: uuid is %@\n", uuid];
            } else {
                [migrationReport appendString:@"Migration: no uuid"];
            }
            
            if ([cdObservation respondsToSelector:@selector(syncedAt)]) {
                NSDate *syncDate = [cdObservation performSelector:@selector(syncedAt)];
                [migrationReport appendFormat:@"Migration: sync date is %@\n", syncDate];
            } else {
                [migrationReport appendString:@"Migration: no sync date"];
            }
            
            if ([cdObservation respondsToSelector:@selector(updatedAt)]) {
                NSDate *updatedDate = [cdObservation performSelector:@selector(updatedAt)];
                [migrationReport appendFormat:@"Migration: updated date is %@\n", updatedDate];
            } else {
                [migrationReport appendString:@"Migration: no updated date"];
            }
            
            // update the progress UI
            processedObservations += 1;
            CGFloat progress = (CGFloat)processedObservations / totalObservations;
            [Analytics.sharedClient debugLog:@"Migration: updating progress"];
            progressBlock(progress);
            
            NSError *error = nil;
            NSDictionary *value = [ExploreObservationRealm valueForCoreDataModel:cdObservation error:&error];
            [migrationReport appendFormat:@"Migration: migration value is %@\n", value];
            
            if (!value) {
                if (error) {
                    NSString *report = [NSString stringWithFormat:@"processed %ld of %ld, then bailed, got nil value for cd observation: %@",
                                        (long)processedObservations,
                                        (long)totalObservations,
                                        error.localizedDescription];
                    done(NO, report, error);
                    return;
                } else {
                    // should be safe to skip
                    skippedObservations += 1;
                    continue;
                }
            }
            [realm beginWriteTransaction];
            ExploreObservationRealm *o = [ExploreObservationRealm createOrUpdateInRealm:realm
                                                                              withValue:value];
            [realm commitWriteTransaction];
            if (!o) {
                
                NSError *error = [[NSError alloc] initWithDomain:@"org.inaturalist"
                                                            code:-1016
                                                        userInfo:@{ NSLocalizedDescriptionKey: @"value failed to insert to realm" }];
                
                [Analytics.sharedClient debugLog:@"Migration: Failed - value failed to insert to realm"];
                [Analytics.sharedClient debugError:error];
                
                NSString *report = [NSString stringWithFormat:@"processed %ld of %ld, then bailed, value failed to insert to realm",
                                    (long)processedObservations, (long)totalObservations];
                done(NO, report, error);
                return;
            }
            
            [migrationReport appendFormat:@"Migration: realm value is %@\n", o];
            [migrationReport appendFormat:@"Migration: realm uploadable representation is %@\n", [o uploadableRepresentation]];
            
            [Analytics.sharedClient debugLog:[NSString stringWithFormat:@"Migration: completed %ld of %ld",
                                              (long)processedObservations, (long)totalObservations]];
        }
        
        NSString *report;
        if (totalObservations == 0 && processedObservations == 0) {
            [Analytics.sharedClient debugLog:@"Migration: Empty Migration"];
            report = @"Nothing to migrate.";
        }  else {
            [Analytics.sharedClient debugLog:@"Migration: Finished"];
            report =  [NSString stringWithFormat:@"processed %ld of %ld, skipped %ld, completed successfully",
                       (long)processedObservations,
                       (long)totalObservations,
                       (long)skippedObservations];;
        }
        
        NSInteger obsCountWithNilUUID = 0;
        for (ExploreObservationRealm *o in [ExploreObservationRealm allObjects]) {
            if (![o uuid]) {
                obsCountWithNilUUID += 1;
            }
        }
        if (obsCountWithNilUUID > 0) {
            report =  [NSString stringWithFormat:@"processed %ld of %ld, skipped %ld, completed. %ld observations with nil uuids, which will FAIL AT UPLOAD.",
                       (long)processedObservations,
                       (long)totalObservations,
                       (long)skippedObservations,
                       (long)obsCountWithNilUUID];
        }
        
        done(YES, migrationReport, nil);
    }
}

@end
