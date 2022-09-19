//
//  Fave.m
//  
//
//  Created by Alex Shepard on 11/20/15.
//
//

#import "Fave.h"
#import "Observation.h"

@implementation Fave

@dynamic observation;
@dynamic faveDate;
@dynamic userIconUrlString;
@dynamic userLogin;
@dynamic userRecordID;

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
