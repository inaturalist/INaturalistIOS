//
//  DeletedRecord.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>

#import "DeletedRecord.h"

@implementation DeletedRecord

@dynamic recordID;
@dynamic modelName;

+ (NSArray *)needingSync
{
    return [self allObjects];
}

+ (NSInteger)needingSyncCount
{
    return self.needingSync.count;
}

@end
