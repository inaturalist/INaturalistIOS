//
//  DeletedRecord.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DeletedRecord : NSManagedObject

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSString * modelName;

+ (NSArray *)needingSync;
+ (NSInteger)needingSyncCount;

@end
