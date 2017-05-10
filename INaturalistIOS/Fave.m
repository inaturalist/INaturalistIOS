//
//  Fave.m
//  
//
//  Created by Alex Shepard on 11/20/15.
//
//

#import "Fave.h"
#import "Observation.h"
#import "User.h"

static RKManagedObjectMapping *defaultMapping = nil;

@implementation Fave

@dynamic observation;
@dynamic faveDate;
@dynamic userIconUrlString;
@dynamic userLogin;
@dynamic userRecordID;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[Fave class]
                                            inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPath:@"created_at" toAttribute:@"faveDate"];
        [defaultMapping mapKeyPath:@"user.id" toAttribute:@"userRecordID"];
        [defaultMapping mapKeyPath:@"user.login" toAttribute:@"userLogin"];
        [defaultMapping mapKeyPath:@"user.user_icon_url" toAttribute:@"userIconUrlString"];

    }
    
    return defaultMapping;
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

#pragma mark - FaveVisualziation

- (NSInteger)userId {
    return self.userRecordID.integerValue;
}

- (NSString *)userName {
    return self.userLogin;
}

- (NSDate *)createdAt {
    return self.faveDate;
}

- (NSURL *)userIconUrl {
    return [NSURL URLWithString:self.userIconUrlString];
}

@end
