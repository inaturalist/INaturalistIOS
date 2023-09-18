//
//  PhotosPageControlCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import AFNetworking;

#import "PhotosPageControlCell.h"
#import "INaturalist-Swift.h"

@implementation PhotosPageControlCell

- (void)awakeFromNib {
    [super awakeFromNib];

    [self.shareButton setImage:[UIImage iconImageWithSystemName:@"square.and.arrow.up.circle.fill" size:IconImageSizeLarge]
                      forState:UIControlStateNormal];
    self.shareButton.tintColor = UIColor.blackColor;
    self.shareButton.backgroundColor = [UIColor clearColor];

    self.shareButton.accessibilityLabel = NSLocalizedString(@"Share", nil);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.iv cancelImageDownloadTask];
    self.pageControl.currentPage = 0;
    self.captiveContainer.hidden = YES;
    // clear all targets/actions
    [self.captiveInfoButton removeTarget:nil
                                  action:NULL
                        forControlEvents:UIControlEventAllEvents];
    [self.shareButton removeTarget:nil
                            action:NULL
                  forControlEvents:UIControlEventAllEvents];
    [self.spinner stopAnimating];
}

@end
