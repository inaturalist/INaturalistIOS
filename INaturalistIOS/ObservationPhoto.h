//
//  ObservationPhoto.h
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Three20/Three20.h>
#import "INatModel.h"

@class Observation;

@interface ObservationPhoto : INatModel <TTPhoto>

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * largeURL;
@property (nonatomic, retain) NSString * license_code;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSString * mediumURL;
@property (nonatomic, retain) NSString * nativePageURL;
@property (nonatomic, retain) NSString * nativeRealName;
@property (nonatomic, retain) NSString * nativeUsername;
@property (nonatomic, retain) NSNumber * observationID;
@property (nonatomic, retain) NSString * originalURL;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSString * smallURL;
@property (nonatomic, retain) NSString * squareURL;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSString * thumbURL;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) Observation *observation;
@property (nonatomic, retain) NSString * photoKey;

@property (nonatomic, assign) id<TTPhotoSource> photoSource;

@end
