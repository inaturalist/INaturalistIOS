//
//  ProjectDetailV2ViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ContainedScrollViewDelegate.h"

@protocol ProjectDetailV2Delegate <NSObject>
- (void)inat_performSegueWithIdentifier:(NSString *)identifier object:(id)object;
@end

@class Project;

@interface ProjectDetailV2ViewController : UIViewController <ProjectDetailV2Delegate, ContainedScrollViewDelegate>

@property Project *project;

@end
