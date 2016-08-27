//
//  GroupingController.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ABSorter.h"
#import "Analytics.h"

NSString *kOnboardingTestName = @"kOnboardingTestName";

#pragma mark - NSUserDefaults Keys
NSString *kInatTestGroupsKey = @"kInatTestGroupsKey";

@implementation ABSorter

+ (NSArray *)assignedTestGroups {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kInatTestGroupsKey];
}

+ (void)sortIntoGroupWithName:(NSString *)name {
    NSString *groupAKey = [self keyForName:name group:@"A"];
    if ([[self assignedTestGroups] containsObject:groupAKey]) {
        return;
    }
    
    NSString *groupBKey = [self keyForName:name group:@"B"];
    if ([[self assignedTestGroups] containsObject:groupBKey]) {
        return;
    }
    
    NSMutableSet *testGroupsMutableSet = [NSMutableSet setWithArray:[self assignedTestGroups]];
    if ([name isEqualToString:kOnboardingTestName]) {
        // onboarding GroupA requires stackView and larger screens than iphone4s
        BOOL isIphone4s = [UIScreen mainScreen].bounds.size.height == 480;
        BOOL hasStackView = NSClassFromString(@"UIStackView") != nil;
        if (arc4random_uniform(10) == 0 && !isIphone4s && hasStackView) {
            [testGroupsMutableSet addObject:groupAKey];
            [testGroupsMutableSet removeObject:groupBKey];
            [[Analytics sharedClient] event:groupAKey
                             withProperties:@{
                                              @"Forced": @"NO",
                                              }];
        } else {
            [testGroupsMutableSet addObject:groupBKey];
            [testGroupsMutableSet removeObject:groupAKey];
            [[Analytics sharedClient] event:groupBKey
                             withProperties:@{
                                              @"Forced": @"NO",
                                              }];

        }
    }
    
    NSArray *testGroups = [testGroupsMutableSet allObjects];
    [[NSUserDefaults standardUserDefaults] setObject:testGroups forKey:kInatTestGroupsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)inGroupAForName:(NSString *)name {
    NSString *groupAKeyForName = [self keyForName:name group:@"A"];
    return [[self assignedTestGroups] containsObject:groupAKeyForName];
}

+ (NSString *)keyForName:(NSString *)name group:(NSString *)group {
    return [NSString stringWithFormat:@"%@-%@", name, group];
}

+ (void)abTestWithName:(NSString *)name A:(void (^)())aBlock B:(void (^)())bBlock {
    [self sortIntoGroupWithName:name];
    
    if ([self inGroupAForName:name]) {
        aBlock();
    } else {
        bBlock();
    }
}

+ (void)forceABSwapForName:(NSString *)name {
    NSString *groupAKey = [self keyForName:name group:@"A"];
    NSString *groupBKey = [self keyForName:name group:@"B"];

    NSMutableSet *testGroupsMutableSet = [NSMutableSet setWithArray:[self assignedTestGroups]];
    if ([[self assignedTestGroups] containsObject:groupAKey]) {
        [testGroupsMutableSet addObject:groupBKey];
        [testGroupsMutableSet removeObject:groupAKey];
        [[Analytics sharedClient] event:groupBKey
                         withProperties:@{
                                          @"Forced": @"YES",
                                          }];
    } else {
        [testGroupsMutableSet addObject:groupAKey];
        [testGroupsMutableSet removeObject:groupBKey];
        [[Analytics sharedClient] event:groupAKey
                         withProperties:@{
                                          @"Forced": @"YES",
                                          }];
    }
    
    NSArray *testGroups = [testGroupsMutableSet allObjects];
    [[NSUserDefaults standardUserDefaults] setObject:testGroups forKey:kInatTestGroupsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

