//
//  INatModel.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INatModel.h"
#import "DeletedRecord.h"

static NSDateFormatter *prettyDateFormatter = nil;
static NSDateFormatter *shortDateFormatter = nil;
static NSDateFormatter *isoDateFormatter = nil;
static NSDateFormatter *jsDateFormatter = nil;

@implementation INatModel

@dynamic recordID;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;

+ (NSDateFormatter *)prettyDateFormatter
{
    if (!prettyDateFormatter) {
        prettyDateFormatter = [[NSDateFormatter alloc] init];
        [prettyDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        [prettyDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [prettyDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return prettyDateFormatter;
}

+ (NSDateFormatter *)shortDateFormatter
{
    if (!shortDateFormatter) {
        shortDateFormatter = [[NSDateFormatter alloc] init];
        shortDateFormatter.dateStyle = NSDateFormatterShortStyle;
        shortDateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return shortDateFormatter;
}

+ (NSDateFormatter *)isoDateFormatter
{
    if (!isoDateFormatter) {
        isoDateFormatter = [[NSDateFormatter alloc] init];
        [isoDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        [isoDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
    }
    return isoDateFormatter;
}

// Javascript-like date format, e.g. @"Sun Mar 18 2012 17:07:20 GMT-0700 (PDT)"
+ (NSDateFormatter *)jsDateFormatter
{
    if (!jsDateFormatter) {
        jsDateFormatter = [[NSDateFormatter alloc] init];
        [jsDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        [jsDateFormatter setDateFormat:@"EEE MMM dd yyyy HH:mm:ss 'GMT'Z (zzz)"];
        
        // per #128 and https://groups.google.com/d/topic/inaturalist/8tE0QTT_kzc/discussion
        // the server doesn't want the observed_on field to be localized
        [jsDateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    }
    return jsDateFormatter;
}

+ (NSArray *)matchingRecordIDs:(NSArray *)recordIDs
{
    // if recordIDs is blank or contains one blank string this will return local records where recordID is blank, which is not really what we want, particularly when deleting records
    if (recordIDs.count == 0) {
        return [NSArray array];
    }
    for (NSString *check in recordIDs) {
        if (check.length == 0) {
            return [NSArray array];
        }
    }
	NSFetchRequest *request = [self fetchRequest];
    [request setPredicate:[NSPredicate predicateWithFormat:@"recordID in %@", recordIDs]];
    return [self objectsWithFetchRequest:request];
}

+ (NSArray *)all
{
    NSFetchRequest *request = [self fetchRequest];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:NO];
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor1, sortDescriptor2]];
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
    [request setSortDescriptors:@[sortDescriptor]];
    return request;
}

+ (NSInteger)needingSyncCount
{
    NSError *error = nil;
    return [[NSManagedObjectContext defaultContext] countForFetchRequest:self.needingSyncRequest error:&error];
}

+ (NSInteger)deletedRecordCount
{
    NSFetchRequest *request = [DeletedRecord fetchRequest];
    [request setPredicate:[NSPredicate predicateWithFormat:@"modelName = %@", NSStringFromClass(self)]];
    NSError *error;
    return [[NSManagedObjectContext defaultContext] countForFetchRequest:request error:&error];
}

+ (id)stub
{
    return [[self alloc] init];
}

+ (RKManagedObjectMapping *)mapping
{
    return [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
}

+ (RKManagedObjectMapping *)serializationMapping
{
    return (RKManagedObjectMapping *)[[self mapping] inverseMapping];
}

+ (void)deleteAll
{
    for (INatModel *o in [self allObjects]) {
        o.syncedAt = nil;
        [o deleteEntity];
    }
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
}

+ (NSManagedObjectContext *)managedObjectContext
{
    return [NSManagedObjectContext defaultContext];
}

- (void)save
{
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        NSLog(@"error saving record: %@", error);
    }
}

- (void)willSave
{
    [self updateLocalTimestamps];
    [super willSave];
}

- (void)destroy
{
    [self deleteEntity];
    NSError* error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
}

- (BOOL)needsSync
{
    return self.syncedAt == nil || [self.syncedAt timeIntervalSinceDate:self.localUpdatedAt] < 0;
}

- (NSDictionary *)attributeChanges
{
    NSDictionary *relats = self.class.entityDescription.relationshipsByName;
	NSMutableDictionary *changes = [NSMutableDictionary dictionaryWithDictionary:self.changedValues];
	for (NSString *relatName in relats.keyEnumerator) {
		[changes removeObjectForKey:relatName];
	}
    return changes;
}

// Note: controllers are responsible for setting localUpdatedAt and syncedAt
- (void)updateLocalTimestamps {
    NSDate *now = [NSDate date];
    // if there's a recordID but no localUpdatedAt, assume this came fresh from the website and should be considered synced.
    if (self.recordID && !self.localUpdatedAt) {
        [self setPrimitiveValue:now forKey:@"localUpdatedAt"];
        [self setPrimitiveValue:now forKey:@"syncedAt"];
    }
    
    // if we don't have a local creation date, assume this came from the server
    if (![self primitiveValueForKey:@"localCreatedAt"]) {
        // try to use server creation date for localCreatedAt
        // if we don't have a local creation date
        [self setPrimitiveValue:self.createdAt ?: now
                         forKey:@"localCreatedAt"];
        [self setPrimitiveValue:now forKey:@"localUpdatedAt"];
    }
}

@end
