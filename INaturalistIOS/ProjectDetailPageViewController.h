//
//  ProjectDetailPageViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ICViewPager/ViewPagerController.h>

#import "ProjectDetailV2ViewController.h"

@class Project;

@interface ProjectDetailPageViewController : ViewPagerController

@property Project *project;
@property (assign) id <ProjectDetailV2Delegate> projectDetailDelegate;
@property (assign) id <ContainedScrollViewDelegate> containedScrollViewDelegate;

@end
