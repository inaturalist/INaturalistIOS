//
//  TutorialSinglePageViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/9/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialSinglePageViewController : UIViewController

@property UIImage *tutorialImage;
@property NSString *tutorialTitle;
@property NSString *tutorialSubtitleOne;
@property NSString *tutorialSubtitleTwo;

@end

extern NSString *kDefaultsKeyTutorialNeverAgain;

extern NSString *kDefaultsKeyTutorialSeenNewObs;
extern NSString *kDefaultsKeyTutorialSeenEditObs;
extern NSString *kDefaultsKeyTutorialSeenNewObsCommunity;
extern NSString *kDefaultsKeyTutorialSeenExplore;
extern NSString *kDefaultsKeyTutorialSeenProjects;
extern NSString *kDefaultsKeyTutorialSeenGuides;

extern NSString *kDefaultsKeyOldTutorialSeen;


