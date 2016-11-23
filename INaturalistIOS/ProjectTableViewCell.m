//
//  ProjectTableViewCell.m
//  iNaturalist
//
//  Created by Eldad Ohana on 7/13/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "ProjectTableViewCell.h"

@implementation ProjectTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Add autolayout.
    [self setupConstraints];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        // Add autolayout.
        [self setupConstraints];
    }
    return self;
}

- (void)setupConstraints{
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.projectImage.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = @{@"titleLabel":self.titleLabel, @"projectImage":self.projectImage};
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.projectImage
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.contentView
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1
                                                      constant:15.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.projectImage
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.contentView
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:7.5]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.projectImage
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:29]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.projectImage
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:29]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.projectImage
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:15]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.contentView
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:-15]];
        
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[titleLabel]|"
                                                                 options:NSLayoutFormatAlignAllRight
                                                                 metrics:0
                                                                   views:views]];
}



@end
