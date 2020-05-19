//
//  ExploreTaxonPhotoRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/17/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import "ExploreTaxonPhoto.h"
#import "INatPhoto.h"

@interface ExploreTaxonPhotoRealm : RLMObject <INatPhoto>

@property NSInteger taxonPhotoId;
@property NSString *attribution;
@property NSString *urlString;
@property NSString *licenseCode;

@property (readonly) NSURL *nativePageUrl;

- (instancetype)initWithMantleModel:(ExploreTaxonPhoto *)model;
+ (NSDictionary *)valueForMantleModel:(ExploreTaxonPhoto *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)model;

@end


RLM_ARRAY_TYPE(ExploreTaxonPhotoRealm)
