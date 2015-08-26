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
        
        self.projectsButton = ({
            
            SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            FAKIcon *projectsIcon = [FAKIonIcons iosBriefcaseOutlineIconWithSize:20];
            [projectsIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            button.leadingTitleLabel.attributedText = projectsIcon.attributedString;
            button.leadingTitleWidth = 34.0f;

            button.trailingTitleLabel.text = NSLocalizedString(@"Projects", @"Title for projects button on the Me tab");
            button.trailingTitleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
            button.trailingTitleLabel.textAlignment = NSTextAlignmentNatural;
            button.separator.hidden = YES;
            
            button.backgroundColor = [UIColor inatLightGray];
            button.tintColor = [UIColor whiteColor];
            
            button;
        });
        [self addSubview:self.projectsButton];
        
        self.guidesButton = ({
            SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            FAKIcon *guidesIcon = [FAKIonIcons iosBookOutlineIconWithSize:20];
            [guidesIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            button.leadingTitleLabel.attributedText = guidesIcon.attributedString;
            button.leadingTitleWidth = 34.0f;

            button.trailingTitleLabel.text = NSLocalizedString(@"Guides", @"Title for guides button on the Me tab");
            button.trailingTitleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
            button.trailingTitleLabel.textAlignment = NSTextAlignmentNatural;
            button.separator.hidden = YES;
            
            button.backgroundColor = [UIColor inatLightGray];
            button.tintColor = [UIColor whiteColor];

            
            button;
        });
        [self addSubview:self.guidesButton];
        
        NSDictionary *views = @{
                                @"icon": self.iconButton,
                                @"obsCount": self.obsCountLabel,
                                @"uploadingSpinner": self.uploadingSpinner,
                                @"projects": self.projectsButton,
                                @"guides": self.guidesButton,
                                };
        
        self.titleConstraintsWithSpinner = [NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[icon(==80)]-10-[uploadingSpinner]-[obsCount]-|"
                                                                                   options:0
                                                                                   metrics:0
                                                                                     views:views];
        self.titleConstraintsWithoutSpinner = [NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[icon(==80)]-10-[obsCount]-|"
                                                                                      options:0
                                                                                      metrics:0
                                                                                        views:views];
        [self addConstraints:self.titleConstraintsWithoutSpinner];        
        
        // project and guide buttons are 150pts max width, prefer to expand to fill the available space
        // within the space between the icon and the right edge of superview, projects and guides should be left aligned
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10@100)-[icon(==80)]-(10@910)-[projects(<=150,==150@900)]-[guides(==projects)]-(10@900)-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[uploadingSpinner]-8-[projects(==30)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[uploadingSpinner]-8-[guides(==30)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[obsCount]-8-[projects(==30)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[obsCount]-8-[guides(==30)]"
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
