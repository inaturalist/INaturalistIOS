//
//  GuidePhotoXML.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 10/2/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "RXMLElement.h"
#import "RXMLElement+Helpers.h"
#import "GuideTaxonXML.h"

@interface GuideImageXML : NSObject <TTPhoto>
@property (nonatomic, strong) GuideTaxonXML *guideTaxon;
@property (nonatomic, strong) RXMLElement *xml;
// TTPhoto attributes
@property (nonatomic, assign) id<TTPhotoSource> photoSource;
@property (nonatomic, assign) int index;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, copy) NSString *caption;

- (id)initWithGuideTaxon:(GuideTaxonXML *)guideTaxon andXML:(RXMLElement *)xml;
- (NSString *)localThumbURL;
- (NSString *)localSmallURL;
- (NSString *)localMediumURL;
- (NSString *)localLargeURL;
- (NSString *)remoteThumbURL;
- (NSString *)remoteSmallURL;
- (NSString *)remoteMediumURL;
- (NSString *)remoteLargeURL;
@end
