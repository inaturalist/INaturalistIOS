//
//  NSString+Inflections.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Inflections)

- (NSString *)underscore;
//- (NSString *)camelize;
- (NSString *)pluralize;
@end
