//
//  AddFaveCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/21/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "AddFaveCell.h"
#import "UIColor+INaturalist.h"

@interface AddFaveCell () {
    BOOL _faved;
}
@end

@implementation AddFaveCell

- (void)awakeFromNib {
    self.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.1f];

    self.faveContainer.layer.cornerRadius = self.faveContainer.bounds.size.height / 2.0f;
    self.faveContainer.layer.borderColor = [UIColor inatTint].CGColor;
    self.faveContainer.layer.borderWidth = 1.0f;
    self.faveContainer.clipsToBounds = YES;
    
    self.faveCountLabel.layer.cornerRadius = self.faveCountLabel.bounds.size.height / 2.0f;
    self.faveCountLabel.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
    
    
    
}

- (void)setFaved:(BOOL)faved {
    _faved = faved;
    
    if (faved) {
        self.faveContainer.backgroundColor = [UIColor inatTint];

        self.faveActionLabel.text = NSLocalizedString(@"Faved", nil);
        self.faveActionLabel.textColor = [UIColor whiteColor];
        
        self.faveCountLabel.textColor = [UIColor whiteColor];
        self.faveCountLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f];

        self.starLabel.textColor = [UIColor whiteColor];
        self.starLabel.attributedText = [[FAKIonIcons iosStarIconWithSize:25] attributedString];
    } else {
        self.faveContainer.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.1f];

        self.faveActionLabel.text = NSLocalizedString(@"Add to Favorites", nil);
        self.faveActionLabel.textColor = [UIColor inatTint];
        
        self.faveCountLabel.textColor = [UIColor whiteColor];
        self.faveCountLabel.backgroundColor = [UIColor inatTint];
        
        self.starLabel.textColor = [UIColor inatTint];
        self.starLabel.attributedText = [[FAKIonIcons iosStarOutlineIconWithSize:25] attributedString];
    }
}

- (BOOL)faved {
    return _faved;
}

@end
