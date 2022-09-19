//
//  NSAttributedString+InatHelpers.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "NSAttributedString+InatHelpers.h"

@implementation NSAttributedString (InatHelpers)


+ (instancetype)inat_attrStrWithBaseStr:(NSString *)baseStr
                              baseAttrs:(NSDictionary *)baseAttrs
                               emSubstr:(NSString *)emSubStr
                                emAttrs:(NSDictionary *)emAttrs {
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:baseStr];
    [attrString addAttributes:baseAttrs range:NSMakeRange(0, baseStr.length)];
    
    if ([baseStr rangeOfString:emSubStr].location != NSNotFound) {
        [attrString addAttributes:emAttrs range:[baseStr rangeOfString:emSubStr]];
    }

    return attrString;
    
}

@end
