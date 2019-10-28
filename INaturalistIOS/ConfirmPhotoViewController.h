//
//  ConfirmPhotoViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Taxon;
@class Project;
@class MultiImageView;

@interface ConfirmPhotoViewController : UIViewController

@property UIImage *image;
@property NSDictionary *metadata;

@property CLLocation *photoTakenLocation;
@property NSDate *photoTakenDate;

@property BOOL shouldContinueUpdatingLocation;
@property BOOL isSelectingFromLibrary;

@property Taxon *taxon;
@property Project *project;

@property (nonatomic, copy) void(^confirmFollowUpAction)(NSArray *confirmedImages);

@property MultiImageView *multiImageView;

@end
