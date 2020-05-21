//
//  InaturalistRealmMigration.h
//  iNaturalist
//
//  Created by Alex Shepard on 4/12/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InaturalistRealmMigration : NSObject

typedef void(^INatRealmMigrationCompletionHandler)(BOOL success, NSError *error);
typedef void(^INatRealmMigrationProgressHandler)(CGFloat progress);

- (void)migrateObservationsToRealmProgress:(INatRealmMigrationProgressHandler)progress finished:(INatRealmMigrationCompletionHandler)done;

- (void)migrateObservationsToRealmFinished:(INatRealmMigrationCompletionHandler)done;

@end
