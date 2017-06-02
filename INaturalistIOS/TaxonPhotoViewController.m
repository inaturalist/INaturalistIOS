//
//  TaxonPhotoViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "TaxonPhotoViewController.h"
#import "ExploreTaxonPhotoRealm.h"

@interface TaxonPhotoViewController ()
@property IBOutlet UIView *licenseScrim;
@property IBOutlet UIImageView *blurredImageView;
@end

@implementation TaxonPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.etpr) {
        __weak typeof(self)weakSelf = self;
        [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:self.etpr.mediumUrl]
                              placeholderImage:self.backupImage
                                       success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                           weakSelf.blurredImageView.image = image;
                                           weakSelf.imageView.image = image;
                                       } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                           weakSelf.blurredImageView.image =nil;
                                           weakSelf.imageView.image = nil;
                                       }];

        self.licenseLabel.text = self.etpr.attribution;
        self.licenseScrim.hidden = NO;
    } else {
        [self.imageView setImage:self.backupImage];
        self.licenseLabel.text = nil;
        self.licenseScrim.hidden = YES;
    }
}

@end
