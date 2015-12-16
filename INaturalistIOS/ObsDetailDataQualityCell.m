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

@property UIView *casualToNeedsIDBar;
@property UIView *needsIDToResearchBar;
@end

@implementation ObsDetailDataQualityCell

- (void)awakeFromNib {
    // Initialization code
    
    self.casualLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.needsIDLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    self.researchLabel.textColor = [UIColor colorWithHexString:@"#c8c7cc"];
    
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
    // 10 px tall
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.casualToNeedsIDBar
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0f
                                                      constant:10]];
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
    // 10 px tall
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.needsIDToResearchBar
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0f
                                                      constant:10]];

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
    }
}

- (ObsDataQuality)dataQuality {
    return _dataQuality;
}

@end
