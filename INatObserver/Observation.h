//
//  Observation.h
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/15/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Observation : NSManagedObject {
    
}

@property (nonatomic, retain) NSString * species_guess;
@property (nonatomic, retain) NSNumber * taxon_id;
@property (nonatomic, retain) NSString * inat_description;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * positional_accuracy;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSDate * updated_at;
@property (nonatomic, retain) NSNumber * local_id;
@property (nonatomic, retain) NSDate * local_created_at;
@property (nonatomic, retain) NSDate * local_updated_at;
@property (nonatomic, retain) NSDate * observed_on;
@property (nonatomic, retain) NSString * observed_on_string;
@property (nonatomic, retain) NSNumber * user_id;
@property (nonatomic, retain) NSString * place_guess;
@property (nonatomic, retain) NSNumber * id_please;
@property (nonatomic, retain) NSNumber * iconic_taxon_id;
@property (nonatomic, retain) NSNumber * private_latitude;
@property (nonatomic, retain) NSNumber * private_longitude;
@property (nonatomic, retain) NSNumber * private_positional_accuracy;
@property (nonatomic, retain) NSString * geoprivacy;
@property (nonatomic, retain) NSString * quality_grade;
@property (nonatomic, retain) NSString * positioning_method;
@property (nonatomic, retain) NSString * positioning_device;
@property (nonatomic, retain) NSNumber * out_of_range;
@property (nonatomic, retain) NSString * license;
@property (nonatomic, retain) NSDate * synced_at;

# pragma mark INRecord methods?
+ (NSArray *)all;
//+ (Observation *)find:(int)id;
//+ (NSArray *)recent;
//+ (NSArray *)recent:(int)limit;
//+ (void)sync;
+ (Observation *)stub;
+ (RKManagedObjectMapping *)mapping;
+ (RKManagedObjectMapping *)serializationMapping;
- (void)save;
- (void)destroy;

@end
