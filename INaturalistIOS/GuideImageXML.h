//
//  GuidePhotoXML.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 10/2/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RXMLElement.h"
#import "RXMLElement+Helpers.h"
#import "GuideTaxonXML.h"
#import "INatPhoto.h"

@interface GuideImageXML : NSObject <INatPhoto>
@property (nonatomic, strong) GuideTaxonXML *guideTaxon;
@property (nonatomic, strong) RXMLElement *xml;
- (id)initWithGuideTaxon:(GuideTaxonXML *)guideTaxon andXML:(RXMLElement *)xml;
- (NSString *)urlForTextAtXPath:(NSString *)xpath;
- (NSString *)pathForTextAtXPath:(NSString *)xpath;
@end
