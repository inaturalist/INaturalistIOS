//
//  GroupingController.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ABSorter : NSObject

+ (void)abTestWithName:(NSString *)name A:(void (^)())aBlock B:(void (^)())bBlock;
+ (void)forceABSwapForName:(NSString *)name;
@end

extern NSString *kOnboardingTestName;
