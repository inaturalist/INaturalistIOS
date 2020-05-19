//
//  InaturalistRealmMigration.h
//  iNaturalist
//
//  Created by Alex Shepard on 4/12/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InaturalistRealmMigration : NSObject

- (void)migrateTaxaToRealm;
- (void)migrateObservationsToRealm;

@end
