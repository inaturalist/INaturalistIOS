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
#import "INatPhoto.h"

@interface GuideTaxonXML : NSObject <INatPhoto>
@property (strong, nonatomic) GuideXML *guide;
@property (strong, nonatomic) RXMLElement *xml;
@property (strong, nonatomic) NSArray *guidePhotos;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSString *taxonID;
- (id)initWithGuide:(GuideXML *)guide andXML:(RXMLElement *)xml;
@end
