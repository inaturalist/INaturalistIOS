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

@implementation MediaPageControlCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.shareButton.layer.cornerRadius = 31.0 / 2;
    self.shareButton.clipsToBounds = YES;
    self.shareButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
    
    FAKIcon *share = [FAKIonIcons iosUploadOutlineIconWithSize:20];
    [share addAttribute:NSForegroundColorAttributeName
                  value:[UIColor whiteColor]];
    [self.shareButton setAttributedTitle:share.attributedString
                                forState:UIControlStateNormal];
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
