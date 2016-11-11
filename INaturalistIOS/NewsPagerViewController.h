//
//  NewsPagerViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/21/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ICViewPager/ViewPagerController.h>

@class SiteNewsViewController;
@class UpdatesViewController;

@interface NewsPagerViewController : ViewPagerController
@property BOOL shouldShowUpdatesOnLoad;
@property SiteNewsViewController *siteNews;
@property UpdatesViewController *updates;
@end
