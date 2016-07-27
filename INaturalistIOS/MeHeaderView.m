//
//  MeHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/11/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "MeHeaderView.h"
#import "UIColor+INaturalist.h"
#import <FontAwesomeKit/FAKIonIcons.h>

@interface MeHeaderView ()
@property BOOL isAnimating;
@property NSArray *titleConstraintsWithSpinner;
@property NSArray *titleConstraintsWithoutSpinner;
@end

@implementation MeHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor inatDarkGray];
        
        self.iconButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button.imageView.contentMode = UIViewContentModeScaleAspectFill;
            button.backgroundColor = [UIColor inatTint];
            button.contentMode = UIViewContentModeScaleAspectFill;
            button.layer.borderColor = [UIColor whiteColor].CGColor;
            button.layer.borderWidth = 2.0f;
            button.layer.cornerRadius = 40.0f;      // circular with an 80x80 frame
            
            button.clipsToBounds = YES;
            
            button;
        });
        [self addSubview:self.iconButton];
                
        self.obsCountLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:18.0f];
            label.textColor = [UIColor whiteColor];
            label.textAlignment = NSTextAlignmentNatural;

            label;
        });
        [self addSubview:self.obsCountLabel];
        
        self.uploadingSpinner = ({
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            spinner.translatesAutoresizingMaskIntoConstraints = NO;
            
            spinner.color = [UIColor whiteColor];
            spinner.hidden = YES;
            
            spinner;
        });
        [self addSubview:self.uploadingSpinner];
        
        NSDictionary *views = @{
                                @"icon": self.iconButton,
                                @"obsCount": self.obsCountLabel,
                                @"uploadingSpinner": self.uploadingSpinner,
                                };
        
        self.titleConstraintsWithSpinner = [NSLayoutConstraint constraintsWithVisualFormat:@"|-16-[icon(==80)]-(10@900)-[uploadingSpinner]-[obsCount]-16-|"
                                                                                   options:0
                                                                                   metrics:0
                                                                                     views:views];
        self.titleConstraintsWithoutSpinner = [NSLayoutConstraint constraintsWithVisualFormat:@"|-16-[icon(==80)]-10-[obsCount]-16-|"
                                                                                      options:0
                                                                                      metrics:0
                                                                                        views:views];
        [self addConstraints:self.titleConstraintsWithoutSpinner];        
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-18-[obsCount]-18-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-18-[uploadingSpinner]-18-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconButton
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconButton
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:80.0f]];

        
    }
    
    return self;
}

- (void)startAnimatingUpload {
    self.uploadingSpinner.hidden = NO;
    [self.uploadingSpinner startAnimating];
    [self removeConstraints:self.titleConstraintsWithoutSpinner];
    [self addConstraints:self.titleConstraintsWithSpinner];
    [self setNeedsDisplay];
}

- (void)stopAnimatingUpload {
    self.uploadingSpinner.hidden = YES;
    [self.uploadingSpinner stopAnimating];
    [self removeConstraints:self.titleConstraintsWithSpinner];
    [self addConstraints:self.titleConstraintsWithoutSpinner];
    [self setNeedsDisplay];
}


@end
