//
//  GuidePhotoViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 10/2/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuidePhotoViewController.h"
#import "PhotoSource.h"
#import "GuideImageXML.h"
#import "Analytics.h"

@implementation GuidePhotoViewController

#pragma mark UIViewController lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateGuidePhoto];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateGuidePhoto];
}

#pragma mark Configure Photosource

- (void)setCurrentURL:(NSString *)currentURL
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^file.*guides/[0-9]+/"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSString *newPath = [regex stringByReplacingMatchesInString:currentURL
                                                        options:0
                                                          range:NSMakeRange(0, currentURL.length)
                                                   withTemplate:@""];
    
    _currentURL = newPath;
    NSString *xpath = [NSString stringWithFormat:@"*[text()='%@']", _currentURL];
    PhotoSource *ps = (PhotoSource *)self.photoSource;
    NSUInteger i = [ps.photos  indexOfObjectPassingTest:^BOOL(GuideImageXML *obj, NSUInteger idx, BOOL *stop) {
        return [obj.xml atXPath:xpath] != nil;
    }];
    if (i && i < ps.numberOfPhotos) {
        _centerPhotoIndex = i;
    }
}

@end
