//
//  TaxonPhotoViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreTaxonPhotoRealm;

@interface TaxonPhotoViewController : UIViewController
@property IBOutlet UIImageView *imageView;
@property IBOutlet UILabel *licenseLabel;
@property IBOutlet ExploreTaxonPhotoRealm *taxonPhoto;
@property UIImage *backupImage;
@end
