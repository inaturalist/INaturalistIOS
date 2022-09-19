//
//  NSFileManager+INaturalist.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/5/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (INaturalist)

+ (CGFloat)freeDiskSpacePercentage;
+ (CGFloat)freeDiskSpaceMB;

@end
