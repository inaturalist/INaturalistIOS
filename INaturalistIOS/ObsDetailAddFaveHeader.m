//
//  AddFaveCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/21/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObsDetailAddFaveHeader.h"
#import "UIColor+INaturalist.h"

@interface ObsDetailAddFaveHeader () {
    BOOL _faved;
    NSInteger _faveCount;
}
@property UILabel *starLabel;
@property UILabel *faveActionLabel;
@property UILabel *faveCountLabel;
@end

@implementation ObsDetailAddFaveHeader

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        self.faveContainer = ({
            UIControl *control = [[UIControl alloc] initWithFrame:CGRectZero];
            control.translatesAutoresizingMaskIntoConstraints = NO;
            
            control.layer.cornerRadius = 43.0f / 2.0f;
            control.layer.borderColor = [UIColor inatTint].CGColor;
            control.layer.borderWidth = 1.0f;
            control.clipsToBounds = YES;
            
            control;
        });
        [self addSubview:self.faveContainer];
        
        NSDictionary *views = @{ @"fave": self.faveContainer };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[fave]-8-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[fave(==43)]-13-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        self.faveCountLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor whiteColor];
            label.clipsToBounds = YES;
            label.layer.cornerRadius = 23.0f / 2.0f;
            
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self.faveContainer addSubview:self.faveCountLabel];
        
        self.faveActionLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label;
        });
        [self.faveContainer addSubview:self.faveActionLabel];
        
        self.starLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textAlignment = NSTextAlignmentCenter;

            label;
        });
        [self.faveContainer addSubview:self.starLabel];
        
        views = @{
                  @"star": self.starLabel,
                  @"label": self.faveActionLabel,
                  @"count": self.faveCountLabel,
                  };
        
        [self.faveContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[star(==23)]-[label]-[count(==23)]-15-|"
                                                                                  options:0
                                                                                  metrics:0
                                                                                     views:views]];
        [self.faveContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[star(==23)]-10-|"
                                                                                   options:0
                                                                                   metrics:0
                                                                                     views:views]];
        [self.faveContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[label(==43)]-0-|"
                                                                                   options:0
                                                                                   metrics:0
                                                                                     views:views]];
        [self.faveContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[count(==23)]-10-|"
                                                                                   options:0
                                                                                   metrics:0
                                                                                     views:views]];
        
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.1f];

    self.faveContainer.layer.cornerRadius = self.faveContainer.bounds.size.height / 2.0f;
    self.faveContainer.layer.borderColor = [UIColor inatTint].CGColor;
    self.faveContainer.layer.borderWidth = 1.0f;
    self.faveContainer.clipsToBounds = YES;
    
    self.faveCountLabel.layer.cornerRadius = self.faveCountLabel.bounds.size.height / 2.0f;
    self.faveCountLabel.clipsToBounds = YES;
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

- (void)setFaveCount:(NSInteger)faveCount {
    _faveCount = faveCount;
    
    self.faveCountLabel.text = [NSString stringWithFormat:@"%ld", (long)_faveCount];
}

- (NSInteger)faveCount {
    return _faveCount;
}



@end
