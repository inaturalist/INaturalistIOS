//
//  ExploreMappingProvider.h
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@interface ExploreMappingProvider : NSObject

+ (RKObjectMapping *)observationMapping;
+ (RKObjectMapping *)observationPhotoMapping;
+ (RKObjectMapping *)locationMapping;
+ (RKObjectMapping *)projectMapping;
+ (RKObjectMapping *)identificationMapping;
+ (RKObjectMapping *)commentMapping;
+ (RKObjectMapping *)taxonMapping;
+ (RKObjectMapping *)personMapping;

@end
