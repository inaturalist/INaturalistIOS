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

@synthesize photoSource = _photoSource;
@synthesize index = _index;
@synthesize size = _size;
@synthesize caption = _caption;

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

#pragma mark - TTPhoto protocol methods
- (NSString *)URLForVersion:(TTPhotoVersion)version
{
    NSString *url;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.localMediumPath]) {
        switch (version) {
            case TTPhotoVersionThumbnail:
                url = self.localThumbURL;
                if (!url) {
                    url = self.localSmallURL;
                }
                break;
            case TTPhotoVersionSmall:
                url = self.localSmallURL;
                if (!url) {
                    url = self.localMediumURL;
                }
                break;
            case TTPhotoVersionMedium:
                url = self.localMediumURL;
                break;
            case TTPhotoVersionLarge:
                url = self.localLargeURL;
                if (!url) {
                    url = self.localMediumURL;
                }
                break;
            default:
                url = nil;
                break;
        }
    } else {
        switch (version) {
            case TTPhotoVersionThumbnail:
                url = self.remoteThumbURL;
                if (!url) {
                    url = self.remoteSmallURL;
                }
                break;
            case TTPhotoVersionSmall:
                url = self.remoteSmallURL;
                if (!url) {
                    url = self.remoteMediumURL;
                }
                break;
            case TTPhotoVersionMedium:
                url = self.remoteMediumURL;
                break;
            case TTPhotoVersionLarge:
                url = self.remoteLargeURL;
                if (!url) {
                    url = self.remoteMediumURL;
                }
                break;
            default:
                url = nil;
                break;
        }
    }
    return url;
}

- (CGSize)size
{
    // since size is a struct, it sort of already has all its "attributes" in place,
    // but they have been initialized to zero, so this is the equivalent of a null check
    if (_size.width == 0) {
        UIImage *img = [UIImage imageWithContentsOfFile:self.localLargeURL];
        if (img) {
            [self setSize:img.size];
        } else {
            [self setSize:CGSizeMake(0,0)];
        }
    }
    return _size;
}

- (NSString *)caption
{
    if (!_caption) {
        NSString *desc = [self.xml atXPath:@"dc:description"].text;
        NSString *attribution = [self.xml atXPath:@"attribution"].text;
        if (desc) {
            if (attribution) {
                _caption = [NSString stringWithFormat:@"%@\n%@", desc, attribution];
            } else {
                _caption = desc;
            }
        } else if (attribution) {
            _caption = attribution;
        } else {
            _caption = nil;
        }
    }
    return _caption;
}
@end
