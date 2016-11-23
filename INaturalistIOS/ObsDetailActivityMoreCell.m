//
//  ObsDetailActivityMoreCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/21/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObsDetailActivityMoreCell.h"
#import "UIColor+INaturalist.h"

@implementation ObsDetailActivityMoreCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.agreeButton setTitleColor:[UIColor inatTint]
                           forState:UIControlStateNormal];
    [self.agreeButton setTitleColor:[UIColor lightGrayColor]
                           forState:UIControlStateDisabled];
    
    NSAttributedString *agreeButtonText = ({
        FAKIcon *agreeIcon = [FAKIonIcons iosCheckmarkOutlineIconWithSize:20];
        NSMutableAttributedString *attr = [agreeIcon.attributedString mutableCopy];
        
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        NSString *agreeText = NSLocalizedString(@"Agree", nil);
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:agreeText
                                                                     attributes:@{
                                                                                  NSBaselineOffsetAttributeName: @(3)
                                                                                  }]];
        
        [attr addAttribute:NSForegroundColorAttributeName
                     value:[UIColor inatTint]
                     range:NSMakeRange(0, attr.length)];
        
        attr;
    });
    [self.agreeButton setAttributedTitle:agreeButtonText
                                forState:UIControlStateNormal];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.agreeButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
}

@end
