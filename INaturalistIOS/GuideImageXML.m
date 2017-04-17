//
//  GuidePhotoXML.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 10/2/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideImageXML.h"

@implementation GuideImageXML
@synthesize guideTaxon = _guideTaxon;
@synthesize xml = _xml;

- (id)initWithGuideTaxon:(GuideTaxonXML *)guideTaxon andXML:(RXMLElement *)xml
{
    self = [super init];
    if (self) {
        self.guideTaxon = guideTaxon;
        self.xml = xml;
    }
    return self;
}

- (NSString *)urlForTextAtXPath:(NSString *)xpath
{
    NSString *relativePath = [self.xml atXPath:xpath].text;
    if (relativePath) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self pathForTextAtXPath:xpath]]) {
            return [NSString stringWithFormat:@"documents://guides/%@/%@", self.guideTaxon.guide.identifier, relativePath];
        }
    }
    return nil;
}

- (NSString *)pathForTextAtXPath:(NSString *)xpath
{
    NSString *relativePath = [self.xml atXPath:xpath].text;
    if (relativePath) {
        return [self.guideTaxon.guide.dirPath stringByAppendingPathComponent:relativePath];
    }
    return nil;
}

- (NSString *)localThumbURL
{
    return [self urlForTextAtXPath:@"descendant::href[@type='local' and @size='thumb']"];
}
- (NSString *)localSmallURL
{
    return [self urlForTextAtXPath:@"descendant::href[@type='local' and @size='small']"];
}
- (NSString *)localMediumURL
{
    return [self urlForTextAtXPath:@"descendant::href[@type='local' and @size='medium']"];
}
- (NSString *)localLargeURL
{
    return [self urlForTextAtXPath:@"descendant::href[@type='local' and @size='large']"];
}

- (NSString *)localThumbPath
{
    return [self pathForTextAtXPath:@"descendant::href[@type='local' and @size='thumb']"];
}
- (NSString *)localSmallPath
{
    return [self pathForTextAtXPath:@"descendant::href[@type='local' and @size='small']"];
}
- (NSString *)localMediumPath
{
    return [self pathForTextAtXPath:@"descendant::href[@type='local' and @size='medium']"];
}
- (NSString *)localLargePath
{
    return [self pathForTextAtXPath:@"descendant::href[@type='local' and @size='large']"];
}

- (NSString *)remoteThumbURL
{
    return [self.xml atXPath:@"descendant::href[@type='remote' and @size='thumb']"].text;
}
- (NSString *)remoteSmallURL
{
    return [self.xml atXPath:@"descendant::href[@type='remote' and @size='small']"].text;
}
- (NSString *)remoteMediumURL
{
    return [self.xml atXPath:@"descendant::href[@type='remote' and @size='medium']"].text;
}
- (NSString *)remoteLargeURL
{
    return [self.xml atXPath:@"descendant::href[@type='remote' and @size='large']"].text;
}



#pragma mark - INatPhoto

- (NSURL *)largePhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self localLargePath]])
        return [NSURL URLWithString:[self localLargePath]];
    else if ([self remoteLargeURL])
        return [NSURL URLWithString:[self remoteLargeURL]];
    else
        return [self mediumPhotoUrl];
}

- (NSURL *)mediumPhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self localMediumPath]])
        return [NSURL URLWithString:[self localMediumPath]];
    else if ([self remoteMediumURL])
        return [NSURL URLWithString:[self remoteMediumURL]];
    else
        return [self smallPhotoUrl];
}

- (NSURL *)smallPhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self localSmallPath]])
        return [NSURL URLWithString:[self localSmallPath]];
    else if ([self remoteSmallURL])
        return [NSURL URLWithString:[self remoteSmallURL]];
    else
        return [self thumbPhotoUrl];
}

- (NSURL *)thumbPhotoUrl {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self localThumbPath]])
        return [NSURL URLWithString:[self localThumbPath]];
    else if ([self remoteThumbURL])
        return [NSURL URLWithString:[self remoteThumbURL]];
    else
        return nil;
}

- (NSURL *)squarePhotoUrl {
    return [self thumbPhotoUrl];
}

- (NSString *)photoKey {
    return nil;
}


@end
