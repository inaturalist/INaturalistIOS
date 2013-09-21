//
//  GuideContainerViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/19/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "SWRevealViewController.h"
#import "Guide.h"

@interface GuideContainerViewController : SWRevealViewController
@property (nonatomic, strong) Guide *guide;
- (IBAction)clickedGuideMenuButton:(id)sender;
@end
