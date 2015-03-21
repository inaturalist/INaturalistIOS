//
//  ExploreObservationDetailHeader.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#import "ExploreObservationDetailHeader.h"
#import "ExploreObservation.h"
#import "ExploreObservationPhoto.h"
#import "UIColor+ExploreColors.h"
#import "UIImage+ExploreIconicTaxaImages.h"
#import "UIFont+ExploreFonts.h"
#import "ExploreObservationPhoto+BestAvailableURL.h"

static NSDateFormatter *shortDateFormatter;
static NSDateFormatter *shortTimeFormatter;
static UIImage *userIconPlaceholder;

@interface ExploreObservationDetailHeader () {
    ExploreObservation *_observation;
    
    UIImageView *observerAvatarImageView;
    UILabel *observerNameLabel;
    UILabel *observedDateLabel;
    UILabel *observedTimeLabel;
    
    UILabel *mapPinLabel;
    UILabel *observedLocationLabel;
    UILabel *observedAccuracyLabel;
    
    UIActivityIndicatorView *imageLoadingSpinner;
    
    UIView *separatorView;
    
    CLGeocoder *geocoder;
}
@end

@implementation ExploreObservationDetailHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        FAKIcon *person = [FAKIonIcons iosPersonIconWithSize:30.0f];
        [person addAttribute:NSForegroundColorAttributeName value:[UIColor inatBlack]];
        userIconPlaceholder = [person imageWithSize:CGSizeMake(30.0f, 30.0f)];

        self.backgroundColor = [UIColor whiteColor];
        
        self.layer.borderColor = [UIColor inatGray].CGColor;
        self.layer.borderWidth = 0.5f;
        
        geocoder = [[CLGeocoder alloc] init];
        
        shortDateFormatter = [[NSDateFormatter alloc] init];
        shortDateFormatter.dateStyle = NSDateFormatterShortStyle;
        shortDateFormatter.timeStyle = NSDateFormatterNoStyle;
        
        shortTimeFormatter = [[NSDateFormatter alloc] init];
        shortTimeFormatter.dateStyle = NSDateFormatterNoStyle;
        shortTimeFormatter.timeStyle = NSDateFormatterShortStyle;
        
        self.commonNameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont boldSystemFontOfSize:17.0f];
            label.textColor = [UIColor colorForIconicTaxon:nil];
            
            label;
        });
        [self addSubview:self.commonNameLabel];
        
        self.scientificNameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont italicSystemFontOfSize:12.0f];
            label.textColor = [UIColor inatBlack];
            
            label;
        });
        [self addSubview:self.scientificNameLabel];
        
        self.photoImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            
            iv.backgroundColor = [UIColor clearColor];
            
            iv.userInteractionEnabled = YES;
            
            iv;
        });
        [self addSubview:self.photoImageView];
        
        imageLoadingSpinner = ({
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.translatesAutoresizingMaskIntoConstraints = NO;
            
            spinner.hidden = YES;
            spinner.hidesWhenStopped = YES;
            
            spinner;
        });
        [self.photoImageView addSubview:imageLoadingSpinner];
        
        observerAvatarImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            
            // rounded corners
            iv.layer.cornerRadius = 3.0f;
            iv.layer.borderColor = [UIColor inatGray].CGColor;
            iv.layer.borderWidth = 1.0f;
            
            iv;
        });
        [self addSubview:observerAvatarImageView];
        
        observerNameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:15.0f];
            label.textColor = [UIColor blackColor];
            
            label;
        });
        [self addSubview:observerNameLabel];
        
        mapPinLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            FAKIcon *mapPin = [FAKIonIcons iosLocationIconWithSize:12.0f];
            [mapPin addAttribute:NSForegroundColorAttributeName value:[UIColor inatBlack]];
            label.attributedText = mapPin.attributedString;
            
            label;
        });
        [self addSubview:mapPinLabel];
        
        observedLocationLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:12.0f];
            label.textColor = [UIColor inatBlack];
            
            label;
        });
        [self addSubview:observedLocationLabel];
        
        observedAccuracyLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:10.0f];
            label.textColor = [UIColor inatGray];
            
            label;
        });
        [self addSubview:observedAccuracyLabel];
        
        observedDateLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:12.0f];
            label.textColor = [UIColor inatBlack];
            label.textAlignment = NSTextAlignmentRight;
            
            label;
        });
        [self addSubview:observedDateLabel];
        
        observedTimeLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:12.0f];
            label.textColor = [UIColor inatBlack];
            label.textAlignment = NSTextAlignmentRight;
            
            label;
        });
        [self addSubview:observedTimeLabel];
        
        NSDictionary *views = @{
                                @"commonNameLabel": self.commonNameLabel,
                                @"scientificNameLabel": self.scientificNameLabel,
                                @"photoImageView": self.photoImageView,
                                @"observerAvatarImageView": observerAvatarImageView,
                                @"observerNameLabel": observerNameLabel,
                                @"observedDateLabel": observedDateLabel,
                                @"observedTimeLabel": observedTimeLabel,
                                @"observedAccuracyLabel": observedAccuracyLabel,
                                };
        
        // image loading spinner is centered in the image view
        [self addConstraint:[NSLayoutConstraint constraintWithItem:imageLoadingSpinner
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.photoImageView
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:imageLoadingSpinner
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.photoImageView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];

        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[commonNameLabel]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[scientificNameLabel]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[photoImageView]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        // date and time are pinned to the right
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[observedDateLabel]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[observedTimeLabel]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[observerAvatarImageView(==30)]-[observerNameLabel]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        float photoImageHeight = 180.0f;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
            photoImageHeight = 600.0f;
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.photoImageView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:photoImageHeight]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[commonNameLabel]-0-[scientificNameLabel]-5-[photoImageView]-[observerAvatarImageView(==30)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];        
        
        
        // observer name is top aligned with observer avatar image (-2px)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:observerNameLabel
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:observerAvatarImageView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0f
                                                          constant:-2.0f]];
        
        // map pin is left aligned with observer name label
        [self addConstraint:[NSLayoutConstraint constraintWithItem:mapPinLabel
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:observerNameLabel
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        // map pin is bottom aligned with observer avatar image (-1px)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:mapPinLabel
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:observerAvatarImageView
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0f
                                                          constant:-1.0f]];
        
        // observed location is left aligned with map pin's right (+3px)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:observedLocationLabel
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:mapPinLabel
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0f
                                                          constant:3.0f]];
        // observed location is baseline aligned with map pin's baseline
        [self addConstraint:[NSLayoutConstraint constraintWithItem:observedLocationLabel
                                                         attribute:NSLayoutAttributeBaseline
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:mapPinLabel
                                                         attribute:NSLayoutAttributeBaseline
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        // observed location is right aligned with observed time label's left edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:observedLocationLabel
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                            toItem:observedTimeLabel
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0f
                                                          constant:0.0f]];

        // observed accuracy is left aligned with map's right (+3px)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:observedAccuracyLabel
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:mapPinLabel
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0f
                                                          constant:3.0f]];
        // observed accuracy is bottom aligned with observed location's top
        [self addConstraint:[NSLayoutConstraint constraintWithItem:observedAccuracyLabel
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:observedLocationLabel
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0f
                                                          constant:0.0f]];

        
        // observed on date is baseline aligned with observer name
        [self addConstraint:[NSLayoutConstraint constraintWithItem:observedDateLabel
                                                         attribute:NSLayoutAttributeBaseline
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:observerNameLabel
                                                         attribute:NSLayoutAttributeBaseline
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        // observed on time is baseline aligned with observed location
        [self addConstraint:[NSLayoutConstraint constraintWithItem:observedTimeLabel
                                                         attribute:NSLayoutAttributeBaseline
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:observedLocationLabel
                                                         attribute:NSLayoutAttributeBaseline
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        
    }
    
    return self;
}


- (ExploreObservation *)observation {
    return _observation;
}

- (void)setObservation:(ExploreObservation *)observation {
    _observation = observation;
    
    [self configureViewForObservation:observation];
}

- (void)configureViewForObservation:(ExploreObservation *)observation {
    
    // start with some defaults
    self.photoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.photoImageView.image = [UIImage imageForIconicTaxon:observation.iconicTaxonName];
    
    if (observation.observationPhotos.count > 0) {
        imageLoadingSpinner.hidden = NO;
        [imageLoadingSpinner startAnimating];
        
        ExploreObservationPhoto *photo = (ExploreObservationPhoto *)observation.observationPhotos.firstObject;
        [self.photoImageView sd_setImageWithURL:[NSURL URLWithString:[photo bestAvailableUrlStringMax:ExploreObsPhotoUrlSizeMedium]]
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                          [imageLoadingSpinner stopAnimating];  // automatically hides itself
                                          [self.photoImageView setNeedsDisplay];
                                      }];
        self.photoImageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.photoImageView.layer.borderWidth = 0.0f;
        self.photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    if (observation.commonName && ![observation.commonName isEqualToString:@""]) {
        self.commonNameLabel.text = observation.commonName;
    } else if (observation.speciesGuess && ![observation.speciesGuess isEqualToString:@""]) {
        self.commonNameLabel.text = observation.speciesGuess;
        if ([observation.speciesGuess isEqualToString:observation.taxonName]) {
            self.commonNameLabel.font = [UIFont fontForTaxonRankName:observation.taxonRank
                                                              ofSize:self.commonNameLabel.font.pointSize];
        }
    } else if (observation.taxonName && ![observation.taxonName isEqualToString:@""]) {
        self.commonNameLabel.text = observation.taxonName;
        self.commonNameLabel.font = [UIFont fontForTaxonRankName:observation.taxonRank
                                                          ofSize:self.commonNameLabel.font.pointSize];
    } else {
        self.commonNameLabel.text = NSLocalizedString(@"Something...", nil);
    }
    self.commonNameLabel.textColor = [UIColor colorForIconicTaxon:observation.iconicTaxonName];
    
    // don't show the same name twice
    if (![observation.taxonName isEqualToString:self.commonNameLabel.text])
        self.scientificNameLabel.text = observation.taxonName;
    self.scientificNameLabel.font = [UIFont fontForTaxonRankName:observation.taxonRank ofSize:12.0f];
    
    // eg http://www.inaturalist.org/attachments/users/icons/44845-thumb.jpg
    NSString *observerAvatarUrlString = [NSString stringWithFormat:@"%@/attachments/users/icons/%ld-thumb.jpg",
                                         INatMediaBaseURL, (long)observation.observerId];
    [observerAvatarImageView sd_setImageWithURL:[NSURL URLWithString:observerAvatarUrlString]
                               placeholderImage:userIconPlaceholder
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                          [observerAvatarImageView setNeedsDisplay];
                                      }];
    observerNameLabel.text = observation.observerName;
    
    if (observation.coordinatesObscured) {
        observedLocationLabel.text = NSLocalizedString(@"Location obscured", nil);
        observedLocationLabel.textColor = [UIColor inatGray];
        observedAccuracyLabel.text = @"";
    } else {
        // if there is a positional accuracy for the observation, display it
        if (observation.publicPositionalAccuracy > 0)
            observedAccuracyLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ldm accuracy", nil),
                                          (long)observation.publicPositionalAccuracy];
        
        if (observation.placeGuess && ![observation.placeGuess isEqualToString:@""]) {
            observedLocationLabel.text = observation.placeGuess;
        } else {
            observedLocationLabel.text = [NSString stringWithFormat:@"%f,%f", observation.latitude, observation.longitude];
            // attempt to geocode the lat/lng into a place name
            CLLocation *location = [[CLLocation alloc] initWithLatitude:observation.latitude
                                                              longitude:observation.longitude];
            [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *err) {
                // use the first placemark
                CLPlacemark *placeMark = [placemarks firstObject];
                if (placeMark.areasOfInterest.count > 0) {
                    // use the first area of interest
                    observedLocationLabel.text = placeMark.areasOfInterest.firstObject;
                } else if (placeMark.inlandWater) {
                    observedLocationLabel.text = placeMark.inlandWater;
                } else if (placeMark.ocean) {
                    observedLocationLabel.text = placeMark.ocean;
                } else if (placeMark.locality && placeMark.administrativeArea) {
                    // San Francisco, CA
                    observedLocationLabel.text = [NSString stringWithFormat:@"%@, %@",
                                                  placeMark.locality,
                                                  placeMark.administrativeArea];
                }
            }];
        }
        observedLocationLabel.textColor = [UIColor inatBlack];
    }
    
    NSDate *observedDate;
    if (observation.timeObservedAt) {
        observedDate = observation.timeObservedAt;
        // we can handle time
        @synchronized(shortTimeFormatter) {
            observedTimeLabel.text = [shortTimeFormatter stringFromDate:observedDate];
        }
        observedTimeLabel.hidden = NO;
    } else {
        observedDate = observation.observedOn;
        // can't handle time
        observedTimeLabel.hidden = YES;
        observedTimeLabel.text = @"";
    }
    
    @synchronized(shortDateFormatter) {
        observedDateLabel.text = [shortDateFormatter stringFromDate:observedDate];
    }
    
}

+ (CGFloat)heightForObservation:(ExploreObservation *)observation {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return 700;
    else
        return 280;
}


@end
