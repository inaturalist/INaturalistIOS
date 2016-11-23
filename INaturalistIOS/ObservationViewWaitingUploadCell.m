//
//  ObservationViewCellWaitingUpload.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonicons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObservationViewWaitingUploadCell.h"
#import "UIColor+INaturalist.h"

@implementation ObservationViewWaitingUploadCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    FAKIcon *upload = [FAKIonIcons iosCloudUploadIconWithSize:30];
    [upload addAttribute:NSForegroundColorAttributeName
                   value:[UIColor inatTint]];
    [self.uploadButton setAttributedTitle:upload.attributedString
                                 forState:UIControlStateNormal];
    
    [upload addAttribute:NSForegroundColorAttributeName
                   value:[UIColor colorWithHexString:@"#969696"]];
    [self.uploadButton setAttributedTitle:upload.attributedString
                                 forState:UIControlStateDisabled];
    
    NSDictionary *views = @{
                            @
                            "uploadButton": self.uploadButton,
                            };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[uploadButton(==44)]-11-|" options:0 metrics:0 views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[uploadButton]-0-|" options:0 metrics:0 views:views]];
}

@end
