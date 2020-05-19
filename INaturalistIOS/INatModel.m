//
//  INatModel.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INatModel.h"

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

+ (NSArray *)matchingRecordIDs:(NSArray *)recordIDs {
    return @[ ];
}

+ (NSArray *)all {
    return @[ ];
}

+ (NSArray *)needingSync {
    return @[ ];
}

+ (NSFetchRequest *)needingSyncRequest {
    NSFetchRequest *request = [self fetchRequest];
    [request setPredicate:[NSPredicate predicateWithFormat:
                           @"syncedAt = nil OR syncedAt < localUpdatedAt"]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    return request;
}

+ (NSInteger)needingSyncCount {
    return 0;
}

+ (id)stub
{
    return [[self alloc] init];
}

+ (void)deleteAll {
    return;
}

- (void)willSave
{
    [self updateLocalTimestamps];
    [super willSave];
}

- (BOOL)needsSync {
    return self.syncedAt == nil || [self.syncedAt timeIntervalSinceDate:self.localUpdatedAt] < 0;
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
