//
//  ConfirmPhotoViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConfirmPhotoViewController : UIViewController

@property UIImage *image;
@property NSArray *assets;
@property NSDictionary *metadata;
@property BOOL shouldContinueUpdatingLocation;

@end
