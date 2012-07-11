//
//  PhotoStub.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 7/9/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "PhotoStub.h"

@implementation PhotoStub
@synthesize url = _url;
@synthesize photoSource = _photoSource;
@synthesize index = _index;
@synthesize size = _size;
@synthesize caption = _caption;

- (id)initWithURL:(NSString *)theURL
{
    self = [super init];
    if (self) {
        self.url = theURL;
    }
    return self;
}

#pragma mark TTPhoto protocol methods
- (NSString *)URLForVersion:(TTPhotoVersion)version
{
    return self.url;
}
@end
