//
//  ConfirmPhotoViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <BlocksKit/BlocksKit.h>
#import <FontAwesomeKit/FAKFontAwesome.h>

#import "ConfirmPhotoViewController.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "MultiImageView.h"
#import "ObservationDetailViewController.h"
#import "TaxaSearchViewController.h"
#import "UIColor+ExploreColors.h"

#define CHICLETWIDTH 100.0f
#define CHICLETHEIGHT 98.0f
#define CHICLETPADDING 2.0

@interface ConfirmPhotoViewController () <ObservationDetailViewControllerDelegate, TaxaSearchViewControllerDelegate> {
    NSArray *iconicTaxa;
    NSFetchRequest *iconicTaxaFetchRequest;
    
    UIImageView *confirmImageView;
    MultiImageView *multiImageView;
    UIScrollView *chicletScrollView;
}
@end

@implementation ConfirmPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"What did you see?", @"Title for the confirm new photo page, which also asks the observer to try making an initial ID");
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip", @"Skip button when picking a species during new photo/new observation confirmation")
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(skip)];
    
    // disable bevel swipe, because it conflicts with the side-scrolling of the iconic taxa chiclets
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    chicletScrollView = ({
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        
        scrollView.backgroundColor = [UIColor whiteColor];
        
        scrollView;
    });
    [self.view addSubview:chicletScrollView];
    
    confirmImageView = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        confirmImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        iv;
    });
    [self.view addSubview:confirmImageView];
    
    multiImageView = ({
        MultiImageView *iv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv;
    });
    [self.view addSubview:multiImageView];
    
    
    NSDictionary *views = @{
                            @"chiclets": chicletScrollView,
                            @"confirm": confirmImageView,
                            @"topLayout": self.topLayoutGuide,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topLayout]-0-[chiclets(==100)]-0-[confirm]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[chiclets]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[confirm]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:multiImageView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:confirmImageView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:multiImageView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:confirmImageView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:multiImageView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:confirmImageView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:multiImageView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:confirmImageView
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1.0f
                                                           constant:0.0f]];

    
    // setup the fetch request for the iconic taxa chiclets
    iconicTaxaFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Taxon"];
    iconicTaxaFetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"defaultName" ascending:YES] ];
    [iconicTaxaFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isIconic == YES"]];
    
    [self loadRemoteIconicTaxa];
}


- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    if (self.image) {
        confirmImageView.image = self.image;
        multiImageView.hidden = YES;
    } else if (self.assets && self.assets.count > 0) {
        confirmImageView.hidden = YES;
        NSArray *images = [self.assets bk_map:^id(ALAsset *asset) {
            return [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
        }];
        multiImageView.images = images;
        multiImageView.hidden = NO;
    }
    
    NSError *fetchError;
    iconicTaxa = [[NSManagedObjectContext defaultContext] executeFetchRequest:iconicTaxaFetchRequest
                                                                        error:&fetchError];
    if (fetchError) {
        [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
    }

    [self configureScrollView];
}

- (void)configureScrollView {

    @synchronized(chicletScrollView) {
        
        if ([chicletScrollView viewWithTag:0x09].subviews.count == iconicTaxa.count + 2)
            return;

        // Thumbnail scrollview content size. Horizontal scrolling only.
        chicletScrollView.contentSize = CGSizeMake(((iconicTaxa.count + 2) * CHICLETWIDTH) + ((iconicTaxa.count + 1) * CHICLETPADDING + 4.0f), 100);
        chicletScrollView.contentOffset = CGPointZero;
        
        // Remove the old content view, in case there was one
        [chicletScrollView.subviews enumerateObjectsUsingBlock:^(UIView *subView, NSUInteger idx, BOOL *stop) {
            [subView removeFromSuperview];
        }];
        
        // Content view for the chiclet scrollview to scroll in
        UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, chicletScrollView.contentSize.width, chicletScrollView.contentSize.height)];
        contentView.tag = 0x09;
        
        [chicletScrollView addSubview:contentView];
        
        // add chiclets to the content view
        for (int i = 0; i < iconicTaxa.count + 2; i++) {
            
            UIControl *chiclet = [[UIControl alloc] initWithFrame:CGRectMake((i * CHICLETWIDTH + i * CHICLETPADDING + 2.0f), 1,
                                                                             CHICLETWIDTH, CHICLETHEIGHT)];
            chiclet.layer.borderColor = [UIColor lightGrayColor].CGColor;
            chiclet.layer.borderWidth = 1.0f;
            chiclet.layer.cornerRadius = 10.0f;
            chiclet.clipsToBounds = YES;
            
            UIView *scrim = [[UIView alloc] initWithFrame:CGRectMake(0, CHICLETHEIGHT - 20 - 1, CHICLETWIDTH, 20)];
            scrim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
            [chiclet addSubview:scrim];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, CHICLETHEIGHT - 20 + 1, CHICLETWIDTH, 20)];
            label.font = [UIFont systemFontOfSize:11.0f];
            label.textColor = [UIColor whiteColor];
            label.textAlignment = NSTextAlignmentCenter;
            [chiclet addSubview:label];
            
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 1, CHICLETWIDTH, CHICLETHEIGHT - 20.0f)];
            iv.contentMode = UIViewContentModeScaleAspectFit;
            [chiclet addSubview:iv];
            
            chiclet.alpha = 0.0f;
            [contentView addSubview:chiclet];
            
            chiclet.tag = i;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(((iconicTaxa.count + 2) - i) * 0.15f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2f animations:^{
                    chiclet.alpha = 1.0f;
                }];
            });
            
            [chiclet addTarget:self action:@selector(tappedControl:) forControlEvents:UIControlEventTouchUpInside];

            if (i == 0) {
                // i know exactly
                FAKIcon *bullsEye = [FAKFontAwesome bullseyeIconWithSize:100];
                [bullsEye addAttribute:NSForegroundColorAttributeName value:[UIColor redColor]];
                iv.image = [bullsEye imageWithSize:CGSizeMake(100, 100)];
                label.text = NSLocalizedString(@"I Know Exactly", @"Label for the I Know Exactly button when ID'ing a new observation");
            } else if (i == iconicTaxa.count + 1) {
                // i have no idea
                iv.image = [UIImage imageNamed:@"unknown-200px.png"];
                label.text = NSLocalizedString(@"No Idea", @"Label for I don't know button when ID'ing a new observation");
            } else {
                Taxon *taxon = [iconicTaxa objectAtIndex:i - 1];
                label.text = taxon.defaultName;
                UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@-200px.png", taxon.name]];
                if (!img)
                    img = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.name];
                iv.image = img;
            }
        }
        
        chicletScrollView.contentOffset = CGPointMake(chicletScrollView.contentSize.width - CHICLETWIDTH, 0.0f);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:2.0f animations:^{
                chicletScrollView.contentOffset = CGPointMake(0.0f, 0.0f);
            }];
        });
    }
}

- (void)reverseGeocodeLocation:(CLLocation *)loc forObservation:(Observation *)obs {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    static CLGeocoder *geoCoder;
    if (!geoCoder)
        geoCoder = [[CLGeocoder alloc] init];
    
    [geoCoder cancelGeocode];       // cancel anything in flight
    
    [geoCoder reverseGeocodeLocation:loc
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       CLPlacemark *placemark = [placemarks firstObject];
                       if (placemark) {
                           @try {
                           obs.placeGuess = [ @[ placemark.name,
                                                 placemark.locality,
                                                 placemark.administrativeArea,
                                                 placemark.ISOcountryCode ] componentsJoinedByString:@", "];
                           } @catch (NSException *exception) {
                               if ([exception.name isEqualToString:NSObjectInaccessibleException])
                                   return;
                               else
                                   @throw exception;
                           }
                       }
                   }];

}

- (void)skip {
    // the kueda case
    [self choseTaxon:nil needId:NO];
}

- (void)tappedControl:(UIControl *)control {
    if (control.tag == 0) {
        // i know
        TaxaSearchViewController *taxaSearch = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL]
                                                instantiateViewControllerWithIdentifier:@"TaxaSearchViewController"];
        taxaSearch.hidesDoneButton = YES;
        taxaSearch.delegate = self;
        [self.navigationController pushViewController:taxaSearch animated:YES];
    } else if (control.tag == iconicTaxa.count + 1) {
        // no idea
        [self choseTaxon:nil needId:YES];
    } else {
        [self choseTaxon:[iconicTaxa objectAtIndex:control.tag - 1] needId:YES];
    }
}

- (void)choseTaxon:(Taxon *)taxon needId:(BOOL)needId {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    ObservationDetailViewController *detail = [storyboard instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
    
     [SVProgressHUD showWithStatus:NSLocalizedString(@"Creating observation...", @"Notice when we're saving a new photo for a new observation")
                          maskType:SVProgressHUDMaskTypeGradient];
    
    
    CLLocationManager *loc = [[CLLocationManager alloc] init];
    
    if (self.image) {
        // embed geo
        NSMutableDictionary *mutableMetadata = [self.metadata mutableCopy];
        if (loc.location) {
            
            double latitude = fabs(loc.location.coordinate.latitude);
            double longitude = fabs(loc.location.coordinate.longitude);
            NSString *latitudeRef = loc.location.coordinate.latitude > 0 ? @"N" : @"S";
            NSString *longitudeRef = loc.location.coordinate.longitude > 0 ? @"E" : @"W";
            
            NSDictionary *gps = @{ @"Latitude": @(latitude), @"Longitude": @(longitude),
                                   @"LatitudeRef": latitudeRef, @"LongitudeRef": longitudeRef };
            
            mutableMetadata[@"{GPS}"] = gps;
        }
        
        
        ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
        [lib writeImageToSavedPhotosAlbum:self.image.CGImage
                                 metadata:mutableMetadata
                          completionBlock:^(NSURL *newAssetUrl, NSError *error) {
                              if (error) {
                                  [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                  NSLog(@"ERROR: %@", error.localizedDescription);
                              }
                          }];
    }
    
    NSDate *now = [NSDate date];
    Observation *o = [Observation object];
    
    o.idPlease = @(needId);
    
    if (taxon) {
        o.taxon = taxon;
        o.taxonID = taxon.recordID;
        o.iconicTaxonName = taxon.iconicTaxonName;
        o.iconicTaxonID = taxon.iconicTaxonID;
        o.speciesGuess = taxon.defaultName;
    }
    
    if (self.image) {
        o.observedOn = now;
        o.localObservedOn = now;
        o.observedOnString = [Observation.jsDateFormatter stringFromDate:o.localObservedOn];

        if (loc.location) {
            o.latitude = @(loc.location.coordinate.latitude);
            o.longitude = @(loc.location.coordinate.longitude);
            o.positionalAccuracy = @(loc.location.horizontalAccuracy);
        }
        
        ObservationPhoto *op = [ObservationPhoto object];
        op.position = @(0);
        [op setObservation:o];
        [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
        [ImageStore.sharedImageStore store:self.image
                                    forKey:op.photoKey];
        op.localCreatedAt = now;
        op.localUpdatedAt = now;
    } else if (self.assets) {
        
        __block BOOL hasDate = NO;
        __block BOOL hasLocation = NO;
        [self.assets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
            ObservationPhoto *op = [ObservationPhoto object];
            op.position = @(idx);
            [op setObservation:o];
            [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
            [ImageStore.sharedImageStore store:[UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage]
                                        forKey:op.photoKey];
            op.localCreatedAt = now;
            op.localUpdatedAt = now;
            
            if (!hasDate) {
                if ([asset valueForProperty:ALAssetPropertyDate]) {
                    hasDate = YES;
                    o.observedOn = [asset valueForProperty:ALAssetPropertyDate];
                    o.observedOnString = [Observation.jsDateFormatter stringFromDate:o.localObservedOn];
                }
            }
            
            if (!hasLocation) {
                NSDictionary *metadata = asset.defaultRepresentation.metadata;
                if ([metadata valueForKeyPath:@"{GPS}.Latitude"] && [metadata valueForKeyPath:@"{GPS}.Longitude"]) {
                    hasLocation = YES;
                    
                    double latitude, longitude;
                    if ([[metadata valueForKeyPath:@"{GPS}.LatitudeRef"] isEqualToString:@"N"]) {
                        latitude = [[metadata valueForKeyPath:@"{GPS}.Latitude"] doubleValue];
                    } else {
                        latitude = -1 * [[metadata valueForKeyPath:@"{GPS}.Latitude"] doubleValue];
                    }
                    
                    if ([[metadata valueForKeyPath:@"{GPS}.LongitudeRef"] isEqualToString:@"E"]) {
                        longitude = [[metadata valueForKeyPath:@"{GPS}.Longitude"] doubleValue];
                    } else {
                        longitude = -1 * [[metadata valueForKeyPath:@"{GPS}.Longitude"] doubleValue];
                    }
                    
                    o.latitude = @(latitude);
                    o.longitude = @(longitude);
                    
                    [self reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:latitude
                                                                            longitude:longitude]
                                  forObservation:o];
                }
                
            }
            
        }];
    }
    
    
    
    NSError *saveError;
    [[Observation managedObjectContext] save:&saveError];
    if (saveError) {
        [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
    }
    
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD showSuccessWithStatus:nil];
    }
    
    detail.observation = o;
    detail.delegate = self;
    detail.shouldShowBigSaveButton = YES;
    [self.navigationController pushViewController:detail animated:YES];
    if (self.shouldContinueUpdatingLocation)
        [detail startUpdatingLocation];
    
}

#pragma mark - ObservationDetailViewController delegate

- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller {
    
    NSError *saveError;
    [[Observation managedObjectContext] save:&saveError];
    if (saveError) {
        [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)observationDetailViewControllerDidCancel:(ObservationDetailViewController *)controller {
    
    @try {
        [controller.observation destroy];
    } @catch (NSException *exception) {
        if ([exception.name isEqualToString:NSObjectInaccessibleException]) {
            // if observation has been deleted or is otherwise inaccessible, do nothing
            return;
        }
    }
}

#pragma mark - TaxaSearchViewControllerDelegate

- (void)taxaSearchViewControllerChoseTaxon:(Taxon *)taxon {
    [self.navigationController popViewControllerAnimated:NO];
    
    [self choseTaxon:taxon needId:NO];
}

#pragma mark - iNat API Request

- (void)loadRemoteIconicTaxa {
    // silently do nothing if we're offline
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/taxa"
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        
                                                        loader.objectMapping = [Taxon mapping];
                                                        
                                                        loader.onDidLoadObjects = ^(NSArray *objects) {
                                                            
                                                            // update timestamps on us and taxa objects
                                                            NSDate *now = [NSDate date];
                                                            [objects enumerateObjectsUsingBlock:^(INatModel *o,
                                                                                                  NSUInteger idx,
                                                                                                  BOOL *stop) {
                                                                [o setSyncedAt:now];
                                                            }];
                                                            
                                                            // save into core data
                                                            NSError *saveError = nil;
                                                            [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                                                            if (saveError) {
                                                                [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
                                                                return;
                                                            }
                                                            
                                                            // update the UI with the merged results
                                                            NSError *fetchError;
                                                            iconicTaxa = [[NSManagedObjectContext defaultContext] executeFetchRequest:iconicTaxaFetchRequest
                                                                                                                                error:&fetchError];
                                                            if (fetchError) {
                                                                [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
                                                            }
                                                            
                                                            [self configureScrollView];
                                                        };
                                                        
                                                        loader.onDidFailLoadWithError = ^(NSError *error) {
                                                            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                        };
                                                        
                                                        loader.onDidFailLoadWithError = ^(NSError *error) {
                                                            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                        };
                                                        
                                                    }];

}

@end
