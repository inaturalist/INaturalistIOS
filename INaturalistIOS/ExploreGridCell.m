//
//  ExploreGridCell.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "ExploreGridCell.h"
#import "ExploreObservation.h"
#import "ExploreObservationPhoto.h"
#import "ExploreTaxon.h"
#import "UIColor+ExploreColors.h"
#import "UIImage+ExploreIconicTaxaImages.h"

@interface ExploreGridCell () {
    ExploreObservation *_observation;
    
    UIImageView *observationImageView;
    UIView *observationScrim;
    UILabel *observationNameLabel;
}
@end

@implementation ExploreGridCell

// designated initializer
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        observationImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            
            iv;
        });
        [self addSubview:observationImageView];
        
        observationScrim = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [[UIColor inatBlack] colorWithAlphaComponent:0.2f];
            
            view;
        });
        [self addSubview:observationScrim];
        
        observationNameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;

            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:14.0f];
            
            label;
        });
        [self addSubview:observationNameLabel];
        
        NSDictionary *views = @{
                                @"observationImageView": observationImageView,
                                @"observationScrim": observationScrim,
                                @"observationNameLabel": observationNameLabel,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[observationImageView]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[observationImageView]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[observationScrim]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[observationNameLabel]-5-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[observationScrim(==20)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[observationNameLabel(==20)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
    }
    
    return self;
}

- (void)prepareForReuse {
    observationImageView.image = nil;
    [observationImageView cancelImageRequestOperation];
    observationNameLabel.text = @"";
}

#pragma mark - observation setter/getter

- (ExploreObservation *)observation {
    return _observation;
}

- (void)setObservation:(ExploreObservation *)observation {
    _observation = observation;
    
    [self configureCellForObservation:observation];
}

- (void)configureCellForObservation:(ExploreObservation *)observation {
    // start by setting the image to the iconic taxon image
    observationImageView.image = [UIImage imageForIconicTaxon:observation.iconicTaxonName];
    
    if (observation.observationPhotos.count > 0) {
        ExploreObservationPhoto *photo = (ExploreObservationPhoto *)observation.observationPhotos.firstObject;
        
        if (photo) {
            NSString *mediumUrlString = [photo.url stringByReplacingOccurrencesOfString:@"square"
                                                                             withString:@"medium"];
            [observationImageView setImageWithURL:[NSURL URLWithString:mediumUrlString]];
        }

    }
    
    if ([observation taxon]) {
        observationNameLabel.text = observation.taxon.commonName ?: observation.taxon.scientificName;
    } else if (observation.speciesGuess) {
        observationNameLabel.text = observation.speciesGuess;
    } else {
        observationNameLabel.text = NSLocalizedString(@"Unknown", @"unknown taxon");
    }
}

@end
