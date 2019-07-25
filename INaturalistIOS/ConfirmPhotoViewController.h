//
//  ConfirmPhotoViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TaxonVisualization.h"
#import "ProjectVisualization.h"

@class MultiImageView;

@interface ConfirmPhotoViewController : UIViewController

@property UIImage *image;
@property NSDictionary *metadata;
@property NSArray *assets;
@property BOOL shouldContinueUpdatingLocation;

@property id <TaxonVisualization> taxon;
@property id <ProjectVisualization> project;

@property (nonatomic, copy) void(^confirmFollowUpAction)(NSArray *confirmedAssets);

@property MultiImageView *multiImageView;

@end
