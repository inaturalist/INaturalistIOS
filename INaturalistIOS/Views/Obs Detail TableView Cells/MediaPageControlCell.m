//
//  MediaPageControlCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

@import FontAwesomeKit;
@import AFNetworking;

#import "MediaPageControlCell.h"
#import "iNaturalist-Swift.h"

@implementation MediaPageControlCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code

    UIImage *share = [UIImage iconImageWithSystemName:@"square.and.arrow.up.circle.fill" size:IconImageSizeMedium];
    [self.shareButton setImage:share
                      forState:UIControlStateNormal];

    self.shareButton.hidden = YES;
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

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

@end
