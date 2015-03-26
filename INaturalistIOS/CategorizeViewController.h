//
//  CategorizeViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/24/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategorizeViewController : UIViewController

@property NSArray *assets;
@property NSDictionary *metadata;
@property BOOL shouldContinueUpdatingLocation;

@end
