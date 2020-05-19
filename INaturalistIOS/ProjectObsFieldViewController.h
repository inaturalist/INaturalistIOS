//
//  ProjectObsFieldViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/13/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreObsFieldValueRealm;
@class ExploreProjectObsFieldRealm;

@interface ProjectObsFieldViewController : UIViewController

@property ExploreObsFieldValueRealm *ofv;
@property ExploreProjectObsFieldRealm *pof;

@end
