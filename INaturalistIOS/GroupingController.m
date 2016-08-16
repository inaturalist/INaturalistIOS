//
//  GroupingController.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "GroupingController.h"
#import "Analytics.h"

#pragma mark - Test Group Names
NSString *kOnboardingGroupA = @"iosOnboardingA";
NSString *kOnboardingGroupB = @"iosOnboardingB";

#pragma mark - NSUserDefaults Keys
NSString *kInatOnboardingGroupWasAssigned = @"kInatOnboardingGroupWasAssigned";
NSString *kInatTestGroupsKey = @"kInatTestGroupsKey";

@implementation GroupingController

- (void)assignDeviceToTestGroups {
    NSArray *testGroups = [self assignedTestGroups];
    if (![testGroups containsObject:kOnboardingGroupA] && ![testGroups containsObject:kOnboardingGroupB]) {
        if (arc4random_uniform(10) == 0) {
            testGroups = [testGroups arrayByAddingObject:kOnboardingGroupA];
            [[Analytics sharedClient] event:kAnalyticsEventAssignedToOnboardingGroupA];
        } else {
            testGroups = [testGroups arrayByAddingObject:kOnboardingGroupB];
            [[Analytics sharedClient] event:kAnalyticsEventAssignedToOnboardingGroupB];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:testGroups forKey:kInatTestGroupsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)deviceInTestGroup:(NSString *)groupName {
    return [[self assignedTestGroups] containsObject:groupName];
}

- (void)assignDeviceToTestGroup:(NSString *)groupName {
    NSMutableArray *testGroupsMutable = [[self assignedTestGroups] mutableCopy];
    if ([groupName isEqualToString:kOnboardingGroupA]) {
        [testGroupsMutable removeObject:kOnboardingGroupB];
        [testGroupsMutable addObject:kOnboardingGroupA];
        [[Analytics sharedClient] event:kAnalyticsEventAssignedToOnboardingGroupA];
    } else if ([groupName isEqualToString:kOnboardingGroupB]) {
        [testGroupsMutable removeObject:kOnboardingGroupA];
        [testGroupsMutable addObject:kOnboardingGroupB];
        [[Analytics sharedClient] event:kAnalyticsEventAssignedToOnboardingGroupB];
    }
    
    NSArray *testGroups = [NSArray arrayWithArray:testGroupsMutable];
    [[NSUserDefaults standardUserDefaults] setObject:testGroups forKey:kInatTestGroupsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)assignedTestGroups {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kInatTestGroupsKey];
}

@end

