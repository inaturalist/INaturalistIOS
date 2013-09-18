//
//  RXMLElement+Helpers.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/16/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "RXMLElement+Helpers.h"

@implementation RXMLElement (Helpers)

/**
 @return A NSString representation of this node
 */
- (NSString *)xmlString {
    NSString *str = nil;
    if (node_ != NULL) {
        
        xmlBufferPtr buff = xmlBufferCreate();
        if (buff) {
            xmlDocPtr doc = NULL;
            int level = 0;
            int format = 1;
            int result = xmlNodeDump(buff, doc, node_, level, format);
            if (result > -1) {
                str = [[NSString alloc] initWithBytes:(xmlBufferContent(buff))
                                               length:(xmlBufferLength(buff))
                                             encoding:NSUTF8StringEncoding];
            }
            xmlBufferFree(buff);
        }
    }
    return str;
}

/**
 Retrieve the first node matching an XPath query.
 */
- (RXMLElement *)atXPath:(NSString *)xpath
{
    NSArray *nodes = [self childrenWithRootXPath:xpath];
    if (nodes.count > 0) {
        return [nodes objectAtIndex:0];
    } else {
        return nil;
    }
}
@end
