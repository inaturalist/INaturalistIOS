//
//  TutorialViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 7/9/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Three20UI/UIToolbarAdditions.h"
#import "TutorialViewController.h"
#import "PhotoStub.h"
#import "PhotoSource.h"
#import "Analytics.h"

@implementation TutorialViewController

@synthesize doneButton = _doneButton;

- (id)initWithDefaultTutorial
{
    NSString *curLang = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    // initialize with an empty photos list
    PhotoSource *photoSource = [[PhotoSource alloc] initWithPhotos:@[]
                                                             title:@"Welcome to iNaturalist!"];
    
    // populate the photoSource with locale-specific tutorial images
    for (int i = 1; i <= 7; i++) {
        NSURL *tutorialItemUrl = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"tutorial%d%@", i, curLang]
                                                         withExtension:@"png"];
        if (!tutorialItemUrl) {
            // if we don't have tutorial files for the user's preferred language,
            // default to english
            tutorialItemUrl = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"tutorial%den", i]
                                                      withExtension:@"png"];
        }
        
        // be defensive
        if (tutorialItemUrl) {
            // PhotoStub takes an argument called URL that's an NSString. Wat?
            PhotoStub *stub = [[PhotoStub alloc] initWithURL:tutorialItemUrl.absoluteString];
            [photoSource.photos addObject:stub];
        }
    }

    self = [super initWithPhotoSource:photoSource];
    return self;
    
}

#pragma mark - UIViewController lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self ensureDoneButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateTutorial];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateTutorial];
}

#pragma mark - UI helpers

- (void)ensureDoneButton
{
    
    if (!self.doneButton) {
        self.doneButton =  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                         target:self 
                                                                         action:@selector(done)];
    }
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

// ugly duplication and override of protected method to make sure it doesn't stomp on our done button
- (void)updateChrome {
    if (_photoSource.numberOfPhotos < 2) {
        self.title = _photoSource.title;
        
    } else {
        self.title = [NSString stringWithFormat:
                      TTLocalizedString(@"%d of %d", @"Current page in photo browser (1 of 10)"),
                      _centerPhotoIndex+1, _photoSource.numberOfPhotos];
    }
    
    UIBarButtonItem* playButton = [_toolbar itemWithTag:1];
    playButton.enabled = _photoSource.numberOfPhotos > 1;
    _previousButton.enabled = _centerPhotoIndex > 0;
    _nextButton.enabled = _centerPhotoIndex >= 0 && _centerPhotoIndex < _photoSource.numberOfPhotos-1;
    
    self.navigationBarStyle = UIBarStyleDefault;
    _toolbar.barStyle = UIBarStyleDefault;
}


- (void)showBars:(BOOL)show animated:(BOOL)animated {
    // overload to ensure navbars are always visible
}

- (void)done
{
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
