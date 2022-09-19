//
//  NSURL+INaturalist.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/18/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (INaturalist)

+ (instancetype)inat_baseURL;
+ (instancetype)inat_baseURLForAuthentication;

@end
