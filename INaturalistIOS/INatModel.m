//
//  INatModel.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INatModel.h"

@implementation INatModel

+ (NSArray *)all
{
    NSFetchRequest *request = [self fetchRequest];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:NO];
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
    return [self objectsWithFetchRequest:request];
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
    if (![self performSelector:NSSelectorFromString(@"localCreatedAt")]) {
        NSLog(@"now");
        NSDate *now = [NSDate date];
        [self performSelector:@selector(setLocalCreatedAt:) withObject:now];
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
            now = [self performSelector:@selector(syncedAt:)];
        } else {
            now = [NSDate date];
        }
        NSDate *stamp = [self performSelector:NSSelectorFromString(@"localUpdatedAt")];
        if (!stamp || [stamp timeIntervalSinceDate:now] < -1) {
            NSLog(@"setting local_updated_at to %@", now);
            [self performSelector:@selector(setLocalUpdatedAt:) withObject:now];
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
