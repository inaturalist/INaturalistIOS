//
//  ConfirmPhotoViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

@import UIKit;
@import Photos;
@class ExploreTaxonRealm;
@class MultiImageView;

NS_ASSUME_NONNULL_BEGIN

@interface ConfirmPhotoViewController : UIViewController

@property NSArray <PHAsset *> *assets;

@property UIImage *image;
@property NSDictionary *metadata;

@property CLLocation *photoTakenLocation;
@property NSDate *photoTakenDate;

@property BOOL shouldContinueUpdatingLocation;
@property BOOL isSelectingFromLibrary;

@property ExploreTaxonRealm * _Nullable taxon;

@property (nonatomic, copy) void(^confirmFollowUpAction)(NSArray *confirmedImages);

@property MultiImageView *multiImageView;

@end

NS_ASSUME_NONNULL_END
