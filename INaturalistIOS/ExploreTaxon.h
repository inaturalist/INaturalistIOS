//
//  ExploreTaxon.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExploreTaxon : NSObject

@property (nonatomic, assign) NSInteger taxonId;
@property (nonatomic, copy) NSString *taxonPhotoUrl;
@property (nonatomic, copy) NSString *taxonWebContent;

@end
