//
//  ExploreIdentificationCell.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ExploreIdentificationCell.h"
#import "ExploreIdentification.h"
#import "UIColor+ExploreColors.h"
#import "UIImage+ExploreIconicTaxaImages.h"

@interface ExploreIdentificationCell () {
    ExploreIdentification *_identification;
    
    UIImageView *identificationImageView;
    UILabel *identificationCommonNameLabel;
    UILabel *identificationScientificNameLabel;
    
    UILabel *identificationBodyLabel;
    
    UILabel *identifierNameDateLabel;
    UIImageView *identifierIconImageView;
}
@end

static UIImage *userIconPlaceholder;

static NSDateFormatter *shortDateFormatter = nil;

@implementation ExploreIdentificationCell

// designated initializer for UITableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        if (!shortDateFormatter) {
            shortDateFormatter = [[NSDateFormatter alloc] init];
            shortDateFormatter.dateStyle = NSDateFormatterShortStyle;
            shortDateFormatter.timeStyle = NSDateFormatterNoStyle;
        }
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        //self.contentView.backgroundColor = [UIColor whiteColor];
        
        FAKIcon *person = [FAKIonIcons ios7PersonIconWithSize:20.0f];
        [person addAttribute:NSForegroundColorAttributeName value:[UIColor inatBlack]];
        userIconPlaceholder = [person imageWithSize:CGSizeMake(20.0f, 20.0f)];

        identificationImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFit;
            // TODO: need a default image
            
            iv;
        });
        [self.contentView addSubview:identificationImageView];
        
        identificationCommonNameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor colorForIconicTaxon:nil];
            label.font = [UIFont boldSystemFontOfSize:14.0f];
            
            label;
        });
        [self.contentView addSubview:identificationCommonNameLabel];
        
        identificationScientificNameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor inatGray];
            label.font = [UIFont italicSystemFontOfSize:11.0f];
            
            label;
        });
        [self.contentView addSubview:identificationScientificNameLabel];
        
        identificationBodyLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor blackColor];
            label.font = [UIFont systemFontOfSize:12.0f];
            label.numberOfLines = 0;
            
            label;
        });
        [self.contentView addSubview:identificationBodyLabel];
        
        identifierNameDateLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor inatGray];
            label.font = [UIFont systemFontOfSize:10.0f];
            label.textAlignment = NSTextAlignmentRight;
            
            label;
        });
        [self.contentView addSubview:identifierNameDateLabel];
        
        identifierIconImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFit;
            iv.layer.cornerRadius = 10.0f;
            iv.clipsToBounds = YES;
            
            iv;
        });
        [self.contentView addSubview:identifierIconImageView];
        
        UIView *separator = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [[UIColor inatGray] colorWithAlphaComponent:0.2];
            
            view;
        });
        [self.contentView addSubview:separator];

        NSDictionary *views = @{
                                @"identificationImageView": identificationImageView,
                                @"identificationCommonNameLabel": identificationCommonNameLabel,
                                @"identificationScientificNameLabel": identificationScientificNameLabel,
                                @"identificationBodyLabel": identificationBodyLabel,
                                @"identifierNameDateLabel": identifierNameDateLabel,
                                @"identifierIconImageView": identifierIconImageView,
                                @"separator": separator,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[identificationImageView(==50)]-5-[identificationCommonNameLabel]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        // scientific name indented four pixels more than common name
        [self addConstraint:[NSLayoutConstraint constraintWithItem:identificationScientificNameLabel
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:identificationCommonNameLabel
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0f
                                                          constant:4.0f]];

        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[identificationBodyLabel]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[identifierNameDateLabel]-[identifierIconImageView(==20)]-10-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        // identifier icon imageview frame is square
        [self addConstraint:[NSLayoutConstraint constraintWithItem:identifierIconImageView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:identifierIconImageView
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[separator]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[identificationImageView(==50)]-5-[identificationBodyLabel]-5-[identifierNameDateLabel]-10-[separator(==1)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:identificationCommonNameLabel
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:identificationImageView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:identificationScientificNameLabel
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:identificationCommonNameLabel
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0f
                                                          constant:3.0f]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:identifierIconImageView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:identifierNameDateLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        

    }
    
    return self;
}

- (ExploreIdentification *)identification {
    return _identification;
}

- (void)setIdentification:(ExploreIdentification *)identification {
    _identification = identification;

    identificationImageView.image = [UIImage imageForIconicTaxon:identification.identificationIconicTaxonName];
                                     
    if (identification.identificationPhotoUrlString) {
        [identificationImageView sd_setImageWithURL:[NSURL URLWithString:identification.identificationPhotoUrlString]
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                              [identificationImageView setNeedsDisplay];
                                          }];
    }
    
    identificationCommonNameLabel.text = identification.identificationCommonName;
    identificationCommonNameLabel.textColor = [UIColor colorForIconicTaxon:identification.identificationIconicTaxonName];
    
    identificationScientificNameLabel.text = identification.identificationScientificName;
    
    NSString *dateString;
    @synchronized(shortDateFormatter) {
        dateString = [shortDateFormatter stringFromDate:identification.identifiedDate];
    }
    identifierNameDateLabel.text = [NSString stringWithFormat:@"Added by %@ on %@.",
                                    identification.identifierName, dateString];
    
    if (identification.identifierIconUrl) {
        [identifierIconImageView sd_setImageWithURL:[NSURL URLWithString:identification.identifierIconUrl]
                                   placeholderImage:userIconPlaceholder
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                              [identifierIconImageView setNeedsDisplay];
                                          }];
    } else {
        identifierIconImageView.image = userIconPlaceholder;
    }
    
    identificationBodyLabel.text = identification.identificationBody;
    
}


+(CGFloat)rowHeightForIdentification:(ExploreIdentification *)identification withWidth:(CGFloat)width {
    CGSize maxSize = CGSizeMake(width, 999.0f);    // max
    UIFont *font = [UIFont systemFontOfSize:12.0f];
    
    if (identification.identificationBody && ![identification.identificationBody isEqualToString:@""]) {
        CGRect textRect = [identification.identificationBody boundingRectWithSize:maxSize
                                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                                   attributes:@{NSFontAttributeName:font}
                                                                      context:nil];
        return textRect.size.height + 101.0f;   // 5 + 50 + 5 + 30 + 10 + 1
    } else {
        return 86;                              // 5 + 50 + 20 + 10 + 1
    }
}


@end
