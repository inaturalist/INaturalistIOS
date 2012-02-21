//
//  INatModel.h
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface INatModel : NSManagedObject
+ (NSArray *)all;
+ (id)stub;
+ (RKManagedObjectMapping *)mapping;
+ (RKManagedObjectMapping *)serializationMapping;
- (void)save;
- (void)destroy;
@end
