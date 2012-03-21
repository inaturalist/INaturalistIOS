//
//  INatModel.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INatModel.h"

@implementation INatModel

@dynamic recordID;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;

+ (NSArray *)all
{
    NSFetchRequest *request = [self fetchRequest];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:NO];
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
    return [self objectsWithFetchRequest:request];
}

+ (NSArray *)needingSync
{
    
    return [self objectsWithFetchRequest:self.needingSyncRequest];
}

+ (NSFetchRequest *)needingSyncRequest
{
    NSFetchRequest *request = [self fetchRequest];
    [request setPredicate:[NSPredicate predicateWithFormat:
                           @"syncedAt = nil OR syncedAt < localUpdatedAt"]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    return request;
}

+ (int)needingSyncCount
{
    NSError *error;
    return [self.managedObjectContext countForFetchRequest:self.needingSyncRequest error:&error];
}

+ (id)stub
{
    return [[self alloc] init];
}

+ (RKManagedObjectMapping *)mapping
{
    return [RKManagedObjectMapping mappingForClass:[self class]];
}

+ (RKManagedObjectMapping *)serializationMapping
{
    return (RKManagedObjectMapping *)[[self mapping] inverseMapping];
}

+ (void)deleteAll
{
    for (INatModel *o in [self allObjects]) {
        [o deleteEntity];
    }
    [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)save
{
    [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)willSave
{
    NSDictionary *relats = self.class.entityDescription.relationshipsByName;
    NSMutableDictionary *changes = [NSMutableDictionary dictionaryWithDictionary:self.changedValues];
    for (NSString *relatName in relats.keyEnumerator) {
        [changes removeObjectForKey:relatName];
    }
    if (changes.count > 0) {
        NSDate *now;
        if ([changes objectForKey:@"syncedAt"]) {
            now = self.syncedAt;
        } else {
            now = [NSDate date];
        }
        NSDate *stamp = self.localUpdatedAt;
        if (!stamp || [stamp timeIntervalSinceDate:now] < -1) {
            [self setPrimitiveValue:now forKey:@"localUpdatedAt"];
            if (![self primitiveValueForKey:@"localCreatedAt"]) {
                [self setPrimitiveValue:now forKey:@"localCreatedAt"];
            }
        }
    }
    [super willSave];
}

- (void)destroy
{
    [self deleteEntity];
    [[[RKObjectManager sharedManager] objectStore] save];
}

- (BOOL)needsSync
{
    return self.syncedAt == nil || [self.syncedAt timeIntervalSinceDate:self.localUpdatedAt] < 0;
}


@end
