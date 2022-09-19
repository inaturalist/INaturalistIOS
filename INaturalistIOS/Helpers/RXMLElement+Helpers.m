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
    NSArray *nodes = [self childrenWithXPath:xpath];
    if (nodes.count > 0) {
        return [nodes objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSArray *)childrenWithXPath:(NSString *)xpath {
    // check for a query
    if (!xpath) {
        return [NSArray array];
    }
    
    xmlXPathContextPtr context = xmlXPathNewContext([self.xmlDoc doc]);
    context->node = node_;
    
    if (context == NULL) {
		return nil;
    }
    
    NSDictionary *namespaces = self.namespaces;
    for (id key in namespaces) {
        xmlXPathRegisterNs(context,
                           (const xmlChar *)[key cStringUsingEncoding:NSUTF8StringEncoding],
                           (const xmlChar *)[[namespaces objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding]
                           );
    }
    
    xmlXPathObjectPtr object = xmlXPathEvalExpression((xmlChar *)[xpath cStringUsingEncoding:NSUTF8StringEncoding], context);
    if(object == NULL) {
		return nil;
    }
    
	xmlNodeSetPtr nodes = object->nodesetval;
	if (nodes == NULL) {
		return nil;
	}
    
	NSMutableArray *resultNodes = [NSMutableArray array];
    
    for (NSInteger i = 0; i < nodes->nodeNr; i++) {
		RXMLElement *element = [RXMLElement elementFromXMLDoc:self.xmlDoc node:nodes->nodeTab[i]];
        
		if (element != NULL) {
			[resultNodes addObject:element];
		}
	}
    
    xmlXPathFreeObject(object);
    xmlXPathFreeContext(context);
    
    return resultNodes;
}

/**
 Return namespaces applying to the current node as an NSDictionary. Dictionary keys are the prefixes, values are the hrefs. Basic implementation derived from Nokogiri.
 TODO: this should really be a property, since there's no need to recalculate these with every query.
 */
- (NSDictionary *)namespaces
{
    NSMutableDictionary *namespaces = [[NSMutableDictionary alloc] init];
    if (!node_) {
        return namespaces;
    }
    xmlNsPtr *ns_list = xmlGetNsList(node_->doc, node_);
    if (!ns_list) return namespaces;
    for (int j = 0 ; ns_list[j] != NULL ; ++j) {
        if (ns_list[j]->href) {
            [namespaces setObject:[NSString stringWithUTF8String:(const char *)ns_list[j]->href]
                           forKey:[NSString stringWithUTF8String:(const char *)ns_list[j]->prefix]];
        }
    }
    xmlFree(ns_list);
    return namespaces;
}

- (void)iterateWithXPath:(NSString *)xpath usingBlock:(void (^)(RXMLElement *))blk
{
    NSArray *children = [self childrenWithXPath:xpath];
    [self iterateElements:children usingBlock:blk];
}
@end
