//
//  ObservationPhoto.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"
#import "INatPhoto.h"

@class Observation;

@interface ObservationPhoto : INatModel <INatPhoto>

@property (nonatomic, retain) NSString * largeURL;
@property (nonatomic, retain) NSString * licenseCode;
@property (nonatomic, retain) NSString * mediumURL;
@property (nonatomic, retain) NSString * nativePageURL;
@property (nonatomic, retain) NSString * nativeRealName;
@property (nonatomic, retain) NSString * nativeUsername;
@property (nonatomic, retain) NSNumber * observationID;
@property (nonatomic, retain) NSString * originalURL;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * smallURL;
@property (nonatomic, retain) NSString * squareURL;
@property (nonatomic, retain) NSString * thumbURL;
@property (nonatomic, retain) Observation *observation;
@property (nonatomic, retain) NSString * photoKey;
@property (nonatomic, retain) NSString * nativePhotoID;
@property (nonatomic, retain) NSString * uuid;

@end

// Overriding accessors for Core Data attributes is a bit weird.  Check out
// https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreData/Articles/cdAccessorMethods.html
@interface ObservationPhoto (PrimitiveAccessors)
- (NSNumber *)primitiveObservationID;
- (void)setPrimitiveObservationID:(NSNumber *)newObservationId;
@end
