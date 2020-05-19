//
//  DeletedRecord.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "DeletedRecord.h"

@implementation DeletedRecord

@dynamic recordID;
@dynamic modelName;

+ (NSArray *)needingSync
{
    return @[ ];
}

+ (NSInteger)needingSyncCount
{
    return 0;
}

@end
