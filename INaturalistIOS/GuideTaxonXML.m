//
//  GuideTaxonXML.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 10/3/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideTaxonXML.h"
#import "GuideImageXML.h"

@implementation GuideTaxonXML
@synthesize guide = _guide;
@synthesize xml = _xml;
@synthesize guidePhotos = _guidePhotos;

- (id)initWithGuide:(GuideXML *)guide andXML:(RXMLElement *)xml
{
    self = [super init];
    if (self) {
        self.xml = xml;
        self.guide = guide;
    }
    return self;
}

- (NSArray *)guidePhotos
{
    if (!_guidePhotos) {
        NSMutableArray *guidePhotos = [[NSMutableArray alloc] init];
        [self.xml iterateWithXPath:@"descendant::GuidePhoto|descendant::GuideRange" usingBlock:^(RXMLElement *element) {
            GuideImageXML *gp = [[GuideImageXML alloc] initWithGuideTaxon:self andXML:element];
            [guidePhotos addObject:gp];
        }];
        _guidePhotos = [NSArray arrayWithArray:guidePhotos];
    }
    return _guidePhotos;
}
@end
