//
//  TaxonPhoto.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/21/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class Taxon;

@interface TaxonPhoto : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSNumber * taxonID;
@property (nonatomic, retain) NSString * nativePhotoID;
@property (nonatomic, retain) NSString * squareURL;
@property (nonatomic, retain) NSString * thumbURL;
@property (nonatomic, retain) NSString * smallURL;
@property (nonatomic, retain) NSString * mediumURL;
@property (nonatomic, retain) NSString * largeURL;
@property (nonatomic, retain) NSString * nativePageURL;
@property (nonatomic, retain) NSString * nativeUsername;
@property (nonatomic, retain) NSString * nativeRealname;
@property (nonatomic, retain) NSString * licenseCode;
@property (nonatomic, retain) NSString * attribution;
@property (nonatomic, retain) Taxon *taxon;

@end
