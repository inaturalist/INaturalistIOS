//
//  TutorialViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 7/9/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>

@interface TutorialViewController : TTPhotoViewController
@property (nonatomic, strong) UIBarButtonItem *doneButton;
- (id)initWithDefaultTutorial;
- (void)done;
- (void)ensureDoneButton;
@end
