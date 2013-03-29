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

@implementation TutorialViewController

@synthesize doneButton = _doneButton;

- (id)initWithDefaultTutorial
{
    NSString *curLang = [[NSLocale preferredLanguages] objectAtIndex:0];
    PhotoSource *photoSouce = [[PhotoSource alloc]
                               initWithPhotos:[NSArray arrayWithObjects:
                                               [[PhotoStub alloc] initWithURL:[NSString stringWithFormat:
                                                                               @"bundle://tutorial1%@.png", curLang]],
                                               [[PhotoStub alloc] initWithURL:[NSString stringWithFormat:
                                                                               @"bundle://tutorial2%@.png", curLang]],
                                               [[PhotoStub alloc] initWithURL:[NSString stringWithFormat:
                                                                               @"bundle://tutorial3%@.png", curLang]],
                                                [[PhotoStub alloc] initWithURL:[NSString stringWithFormat:
                                                                                @"bundle://tutorial4%@.png", curLang]],
                                                [[PhotoStub alloc] initWithURL:[NSString stringWithFormat:
                                                                                @"bundle://tutorial5%@.png", curLang]],
                                                                   nil] 
                                                            title:@"Welcome to iNaturalist!"];
    self = [super initWithPhotoSource:photoSouce];
    return self;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self ensureDoneButton];
}

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
}


- (void)showBars:(BOOL)show animated:(BOOL)animated {
    // overload to ensure navbars are always visible
}

- (void)done
{
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
