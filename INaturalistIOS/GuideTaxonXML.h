//
//  GuideTaxonXML.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 10/3/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "RXMLElement.h"
#import "RXMLElement+Helpers.h"
#import "GuideXML.h"

@interface GuideTaxonXML : NSObject
@property (strong, nonatomic) GuideXML *guide;
@property (strong, nonatomic) RXMLElement *xml;
@property (strong, nonatomic) NSArray *guidePhotos;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *displayName;
- (id)initWithGuide:(GuideXML *)guide andXML:(RXMLElement *)xml;
- (NSString *)localImagePathForSize:(NSString *)size;
- (NSString *)remoteImageURLForSize:(NSString *)size;
@end
