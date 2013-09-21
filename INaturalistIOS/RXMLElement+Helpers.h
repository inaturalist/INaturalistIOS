//
//  RXMLElement+Helpers.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/16/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "RXMLElement.h"

@interface RXMLElement (Helpers)
- (NSString *)xmlString;
- (RXMLElement *)atXPath:(NSString *)xpath;
- (NSDictionary *)namespaces;
@end
