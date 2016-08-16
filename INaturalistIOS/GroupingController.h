//
//  GroupingController.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupingController : NSObject

- (void)assignDeviceToTestGroups;
- (BOOL)deviceInTestGroup:(NSString *)groupName;
- (void)assignDeviceToTestGroup:(NSString *)groupName;
- (NSArray *)assignedTestGroups;

@end

extern NSString *kOnboardingGroupA;
extern NSString *kOnboardingGroupB;
