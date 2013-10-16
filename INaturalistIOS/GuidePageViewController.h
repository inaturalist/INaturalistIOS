//
//  GuidePageViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 10/15/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GuideXML.h"

@interface GuidePageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property (nonatomic, strong) GuideXML *guide;
@property (nonatomic, assign) NSInteger currentPosition;
@property (nonatomic, strong) NSString *currentXPath;
- (IBAction)clickedObserve:(id)sender;
@end
