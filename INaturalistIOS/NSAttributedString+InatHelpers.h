//
//  NSAttributedString+InatHelpers.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (InatHelpers)

+ (instancetype)inat_attrStrWithBaseStr:(NSString *)baseStr
                              baseAttrs:(NSDictionary *)baseAttrs
                               emSubstr:(NSString *)emSubStr
                                emAttrs:(NSDictionary *)emAttrs;

@end
