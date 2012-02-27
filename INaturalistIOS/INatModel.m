//
//  INatModel.m
//  INaturalistIOS
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

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (!self.localCreatedAt) {
        [self setLocalCreatedAt:[NSDate date]];
    }
    return self;
}

- (void)save
{
    [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)willSave
{
    if ([self changedValues] != nil) {
        NSDate *now;
        if ([self.changedValues objectForKey:@"syncedAt"]) {
            now = [self performSelector:@selector(syncedAt)];
        } else {
            now = [NSDate date];
        }
        NSDate *stamp = self.localUpdatedAt;
        if (!stamp || [stamp timeIntervalSinceDate:now] < -1) {
            [self setLocalUpdatedAt:now];
        }
    }
    [super willSave];
}

- (void)destroy
{
    [self deleteEntity];
    [[[RKObjectManager sharedManager] objectStore] save];
}


@end
