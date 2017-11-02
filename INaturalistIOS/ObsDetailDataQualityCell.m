//
//  ObsDetailDataQualityCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/15/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObsDetailDataQualityCell.h"
#import "UIColor+INaturalist.h"

@interface ObsDetailDataQualityCell () {
    ObsDataQuality _dataQuality;
}

@property IBOutlet UILabel *casualLabel;
@property IBOutlet UILabel *needsIDLabel;
@property IBOutlet UILabel *researchLabel;

@property IBOutlet UILabel *casualCheckMark;
@property IBOutlet UILabel *needsIDCheckMark;
@property IBOutlet UILabel *researchCheckMark;

@property IBOutlet UILabel *cantDetermineDataQualityLabel;

@property UIView *casualToNeedsIDBar;
@property UIView *needsIDToResearchBar;
@end

@implementation ObsDetailDataQualityCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.casualLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.needsIDLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.researchLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    
    self.casualLabel.text = NSLocalizedString(@"Casual Grade", @"casual data quality");
    self.needsIDLabel.text = NSLocalizedString(@"Needs ID", @"needs id data quality");
    self.researchLabel.text = NSLocalizedString(@"Research Grade", @"research data quality");
    
    FAKIcon *check = [FAKIonIcons checkmarkIconWithSize:12.0f];
    
    self.casualCheckMark.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.casualCheckMark.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.casualCheckMark.layer.cornerRadius = 21.0 / 2;
    self.casualCheckMark.clipsToBounds = YES;
    self.casualCheckMark.attributedText = check.attributedString;

    self.needsIDCheckMark.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.needsIDCheckMark.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.needsIDCheckMark.layer.cornerRadius = 21.0 / 2;
    self.needsIDCheckMark.clipsToBounds = YES;
    self.needsIDCheckMark.attributedText = check.attributedString;
    
    self.researchCheckMark.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.researchCheckMark.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.researchCheckMark.layer.cornerRadius = 21.0 / 2;
    self.researchCheckMark.clipsToBounds = YES;
    self.researchCheckMark.attributedText = check.attributedString;

    self.cantDetermineDataQualityLabel.attributedText = ({
        NSString *uploadPrompt = NSLocalizedString(@"Please upload to determine data quality", nil);
        NSString *learnMorePrompt = NSLocalizedString(@"Learn more about data quality >", nil);
        
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:uploadPrompt attributes:nil];
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:learnMorePrompt
                                                                     attributes:@{
                                                                                  NSForegroundColorAttributeName: [UIColor inatTint]
                                                                                  }
                                      ]];
        
        attr;
    });
    
    self.casualToNeedsIDBar = ({
        UIView *view = [UIView new];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
        
        view;
    });
    [self insertSubview:self.casualToNeedsIDBar atIndex:0];
//    [self addSubview:self.casualToNeedsIDBar];
    
    self.needsIDToResearchBar = ({
        UIView *view = [UIView new];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];

        view;
    });
    [self insertSubview:self.needsIDToResearchBar atIndex:0];
    
    // casual to needs ID bar constraints
    // vertically centered
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.casualToNeedsIDBar
                                                    attribute:NSLayoutAttributeCenterY
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self
                                                    attribute:NSLayoutAttributeCenterY
                                                   multiplier:1.0f
                                                      constant:0.0f]];
    // 7 pts tall
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.casualToNeedsIDBar
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0f
                                                      constant:7]];
    // left edge in center of casual checkmark
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.casualToNeedsIDBar
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.casualCheckMark
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    // right edge in center of needs id checkmark
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.casualToNeedsIDBar
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.needsIDCheckMark
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    // needs id to research bar constraints
    // vertically centered
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.needsIDToResearchBar
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    // 7 pts tall
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.needsIDToResearchBar
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0f
                                                      constant:7]];

    // left edge in center of needs id checkmark
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.needsIDToResearchBar
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.needsIDCheckMark
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    // right edge in center of research checkmark
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.needsIDToResearchBar
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.researchCheckMark
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];


}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setDataQuality:(ObsDataQuality)dataQuality {
    _dataQuality = dataQuality;
    
    // setup the view
    if (dataQuality == ObsDataQualityCasual) {
        self.casualLabel.textColor = [UIColor inatTint];
        self.casualCheckMark.textColor = [UIColor whiteColor];
        self.casualCheckMark.backgroundColor = [UIColor inatTint];
        
        self.needsIDLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
        self.needsIDCheckMark.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
        self.needsIDCheckMark.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];

        self.researchLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
        self.researchCheckMark.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
        
        self.casualToNeedsIDBar.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
        self.needsIDToResearchBar.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
        
        self.cantDetermineDataQualityLabel.hidden = YES;
    } else if (dataQuality == ObsDataQualityNeedsID) {
        self.casualLabel.textColor = [UIColor inatTint];
        self.casualCheckMark.textColor = [UIColor whiteColor];
        self.casualCheckMark.backgroundColor = [UIColor inatTint];
        
        self.needsIDLabel.textColor = [UIColor inatTint];
        self.needsIDCheckMark.textColor = [UIColor whiteColor];
        self.needsIDCheckMark.backgroundColor = [UIColor inatTint];
        
        self.researchLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
        self.researchCheckMark.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
        self.researchCheckMark.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];

        self.casualToNeedsIDBar.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.8f];
        self.needsIDToResearchBar.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
        
        self.cantDetermineDataQualityLabel.hidden = YES;
    } else if (dataQuality == ObsDataQualityResearch) {
        self.casualLabel.textColor = [UIColor inatTint];
        self.casualCheckMark.textColor = [UIColor whiteColor];
        self.casualCheckMark.backgroundColor = [UIColor inatTint];
        
        self.needsIDLabel.textColor = [UIColor inatTint];
        self.needsIDCheckMark.textColor = [UIColor whiteColor];
        self.needsIDCheckMark.backgroundColor = [UIColor inatTint];
        
        self.researchLabel.textColor = [UIColor inatTint];
        self.researchCheckMark.textColor = [UIColor whiteColor];
        self.researchCheckMark.backgroundColor = [UIColor inatTint];
        
        self.casualToNeedsIDBar.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.8f];
        self.needsIDToResearchBar.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.8f];
        
        self.cantDetermineDataQualityLabel.hidden = YES;
    } else if (dataQuality == ObsDataQualityNone) {
        self.casualLabel.hidden = YES;
        self.casualCheckMark.hidden = YES;
        
        self.needsIDLabel.hidden = YES;
        self.needsIDCheckMark.hidden = YES;
        
        self.researchLabel.hidden = YES;
        self.researchCheckMark.hidden = YES;
        
        self.casualToNeedsIDBar.hidden = YES;
        self.needsIDToResearchBar.hidden = YES;
        
        self.cantDetermineDataQualityLabel.hidden = NO;
        
    }
}

- (ObsDataQuality)dataQuality {
    return _dataQuality;
}

- (void)prepareForReuse {
    self.casualLabel.hidden = NO;
    self.casualCheckMark.hidden = NO;
    
    self.needsIDLabel.hidden = NO;
    self.needsIDCheckMark.hidden = NO;
    
    self.researchLabel.hidden = NO;
    self.researchCheckMark.hidden = NO;
    
    self.casualToNeedsIDBar.hidden = NO;
    self.needsIDToResearchBar.hidden = NO;
    
    self.cantDetermineDataQualityLabel.hidden = YES;
}

@end
