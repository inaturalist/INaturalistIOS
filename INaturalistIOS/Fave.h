//
//  Fave.h
//  
//
//  Created by Alex Shepard on 11/20/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

#import "FaveVisualization.h"

@class Observation, User;

// don't inherit from InatModel, since we don't have recordIDs/etc
@interface Fave : NSManagedObject <FaveVisualization>

@property (nonatomic, retain) NSDate *faveDate;
@property (nonatomic, retain) Observation *observation;
@property (nonatomic, retain) NSString *userLogin;
@property (nonatomic, retain) NSString *userIconUrlString;
@property (nonatomic, retain) NSNumber *userRecordID;

+ (RKManagedObjectMapping *)mapping;

@end
