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
@property NSString *nativePageUrlString;
@property NSString *squareUrlString;
@property NSString *smallUrlString;
@property NSString *mediumUrlString;
@property NSString *largeUrlString;

@property (readonly) NSURL *nativePageUrl;
@property (readonly) NSURL *squareUrl;
@property (readonly) NSURL *smallUrl;
@property (readonly) NSURL *mediumUrl;
@property (readonly) NSURL *largeUrl;


- (instancetype)initWithMantleModel:(ExploreTaxonPhoto *)model;

@end


RLM_ARRAY_TYPE(ExploreTaxonPhotoRealm)
