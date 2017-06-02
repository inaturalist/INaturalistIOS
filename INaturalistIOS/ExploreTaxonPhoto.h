//
//  ExploreTaxonPhoto.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/17/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "INatPhoto.h"

@interface ExploreTaxonPhoto : MTLModel <MTLJSONSerializing, INatPhoto>

@property (nonatomic, assign) NSInteger taxonPhotoId;
@property (nonatomic, copy) NSString *attribution;
@property (nonatomic, copy) NSURL *nativePageUrl;
@property (nonatomic, copy) NSURL *squareUrl;
@property (nonatomic, copy) NSURL *smallUrl;
@property (nonatomic, copy) NSURL *mediumUrl;
@property (nonatomic, copy) NSURL *largeUrl;

@end
