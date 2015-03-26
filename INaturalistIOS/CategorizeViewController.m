//
//  CategorizeViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/24/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HexColors/HexColor.h>

#import "CategorizeViewController.h"
#import "MultiImageView.h"
#import "Taxon.h"
#import "CategoryChiclet.h"
#import "ObservationDetailViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"

static NSDictionary *ICONIC_TAXON_NAMES;
static NSArray *ICONIC_TAXON_ORDER;

@interface CategorizeViewController () <ObservationDetailViewControllerDelegate> {
    UIVisualEffectView  *blurView;
    UIView *scrim;
    
    MultiImageView *bgMultiImageView;
    MultiImageView *multiImageView;

    NSArray *iconicTaxa;
    NSFetchRequest *iconicTaxaFetchRequest;
    UIView *categories;
}
@end

@implementation CategorizeViewController

#pragma mark - UIViewController lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        ICONIC_TAXON_NAMES = @{
                               @"Animalia": @"Animals",
                               @"Actinopterygii": @"Ray-finned Fishes",
                               @"Aves": @"Birds",
                               @"Reptilia": @"Reptiles",
                               @"Amphibia": @"Amphibians",
                               @"Mammalia": @"Mammals",
                               @"Arachnida": @"Arachnids",
                               @"Insecta": @"Insects",
                               @"Plantae": @"Plants",
                               @"Fungi": @"Fungi",
                               @"Protozoa": @"Protozoans",
                               @"Mollusca": @"Mollusks",
                               @"Chromista": @"Chromista"
                               };
        
        ICONIC_TAXON_ORDER = @[
                               @"Mollusca",
                               @"Reptilia",
                               @"Fungi",
                               @"Amphibia",
                               @"Insecta",
                               @"Aves",
                               @"Arachnida",
                               @"Mammalia",
                               @"Plantae",
                               ];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Categorize", @"Title for the categorize page, which also asks the observer to try making an initial ID.");
    
    bgMultiImageView = ({
        MultiImageView *miv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        miv.translatesAutoresizingMaskIntoConstraints = NO;
        
        miv;
    });
    [self.view addSubview:bgMultiImageView];
    
    multiImageView = ({
        MultiImageView *miv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        miv.translatesAutoresizingMaskIntoConstraints = NO;
        
        miv;
    });
    [self.view addSubview:multiImageView];
    
    blurView = ({
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blur.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        blur;
    });
    
    UIVisualEffectView *vibrancy = ({
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:(UIBlurEffect *)blurView.effect];
        UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
        vibrancyEffectView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        vibrancyEffectView;
    });
    [blurView.contentView addSubview:vibrancy];
    
    self.navigationItem.backBarButtonItem.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    blurView.frame = multiImageView.bounds;
    vibrancy.frame = multiImageView.bounds;
    
    [multiImageView addSubview:blurView];
    
    categories = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view;
    });
    [self.view addSubview:categories];
    
    NSDictionary *views = @{
                            @"blur": blurView,
                            @"images": multiImageView,
                            @"bgImages": bgMultiImageView,
                            @"vibrancy": vibrancy,
                            @"categories": categories,
                            @"topLayoutGuide": self.topLayoutGuide,
                            };

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bgImages]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bgImages]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[images]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[images]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topLayoutGuide]-30-[categories]"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:categories
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self loadRemoteIconicTaxa];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    if (self.assets.count > 0) {
        NSArray *images = [self.assets bk_map:^id(ALAsset *asset) {
            return [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
        }];
        multiImageView.images = images;
        bgMultiImageView.images = images;
    } else if (self.assetURL) {
        ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
        [lib assetForURL:self.assetURL
             resultBlock:^(ALAsset *asset) {
                 multiImageView.images = @[ [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage] ];
                 bgMultiImageView.images = multiImageView.images;
             } failureBlock:^(NSError *error) {
                 [SVProgressHUD showErrorWithStatus:error.localizedDescription];
             }];
    }
    
    multiImageView.alpha = 0.0f;
    
    [self configureCategories];
}

- (void)viewDidAppear:(BOOL)animated {
    [UIView animateWithDuration:1.0f
                     animations:^{
                         multiImageView.alpha = 1.0f;
                     }];
}

#pragma mark - UI helper

- (void)configureCategories {
    
    // setup the fetch request for the iconic taxa categories
    iconicTaxaFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Taxon"];
    iconicTaxaFetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"defaultName" ascending:YES] ];
    [iconicTaxaFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isIconic == YES"]];
    
    // local fetch of iconic taxa
    NSError *fetchError;
    iconicTaxa = [[NSManagedObjectContext defaultContext] executeFetchRequest:iconicTaxaFetchRequest
                                                                        error:&fetchError];
    if (fetchError) {
        [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
    }
    
    // sort iconic taxa according to
    iconicTaxa = [iconicTaxa sortedArrayUsingComparator:^NSComparisonResult(Taxon *t, Taxon *t2) {
        return [@([ICONIC_TAXON_ORDER indexOfObject:t.name]) compare:@([ICONIC_TAXON_ORDER indexOfObject:t2.name])];
    }];
    
    // remove all the existing buttons
    [categories.subviews bk_each:^(UIView *view) {
        [view removeFromSuperview];
    }];
    
    // skip fish, other animals, protozoa, chromista
    NSArray *buttons = [[iconicTaxa bk_reject:^BOOL(Taxon *t) {
        if ([t.name isEqualToString:@"Actinopterygii"]) { return YES; }
        if ([t.name isEqualToString:@"Animalia"]) { return YES; }
        if ([t.name isEqualToString:@"Protozoa"]) { return YES; }
        if ([t.name isEqualToString:@"Chromista"]) { return YES; }
        return NO;
    }] bk_map:^id(Taxon *t) {
        CategoryChiclet *chiclet = [CategoryChiclet buttonWithType:UIButtonTypeSystem];
        chiclet.translatesAutoresizingMaskIntoConstraints = NO;
        
        chiclet.categoryLabel.text = ICONIC_TAXON_NAMES[t.name];
        NSString *imageName = [NSString stringWithFormat:@"ic_%@", [ICONIC_TAXON_NAMES[t.name] lowercaseString]];
        chiclet.categoryImageView.image = [UIImage imageNamed:imageName];
        
        chiclet.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        chiclet.layer.borderColor = [UIColor colorWithHexString:@"7a7a7a" alpha:0.5f].CGColor;
        chiclet.layer.borderWidth = 2.0f;
        chiclet.layer.cornerRadius = 2.0f;
        
        [chiclet bk_addEventHandler:^(id sender) {
            [self choseTaxon:t needId:YES];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [categories addSubview:chiclet];
        return chiclet;
    }];
    
    
    NSDictionary *views = @{
                            @"one":     buttons[0],
                            @"two":     buttons[1],
                            @"three":   buttons[2],
                            @"four":    buttons[3],
                            @"five":    buttons[4],
                            @"six":     buttons[5],
                            @"seven":   buttons[6],
                            @"eight":   buttons[7],
                            @"nine":    buttons[8],
                            };
    
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[one(==86)]-5-[two(==86)]-5-[three(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[four(==86)]-5-[five(==86)]-5-[six(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[seven(==86)]-5-[eight(==86)]-5-[nine(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[one(==86)]-5-[four(==86)]-5-[seven(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[two(==86)]-5-[five(==86)]-5-[eight(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[three(==86)]-5-[six(==86)]-5-[nine(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
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


#pragma mark - Taxon Choice helper

- (void)saveObservation:(Observation *)o withAssets:(NSArray *)assets {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    ObservationDetailViewController *detail = [storyboard instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];

    NSDate *now = [NSDate date];

    __block BOOL hasDate = NO;
    __block BOOL hasLocation = NO;
    
    [assets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
        ObservationPhoto *op = [ObservationPhoto object];
        op.position = @(idx);
        [op setObservation:o];
        [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
        [ImageStore.sharedImageStore storeAsset:asset forKey:op.photoKey];
        op.localCreatedAt = now;
        op.localUpdatedAt = now;
        
        if (!hasDate) {
            if ([asset valueForProperty:ALAssetPropertyDate]) {
                hasDate = YES;
                o.observedOn = [asset valueForProperty:ALAssetPropertyDate];
                o.localObservedOn = o.observedOn;
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

- (void)choseTaxon:(Taxon *)taxon needId:(BOOL)needId {
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Creating observation...", @"Notice when we're saving a new photo for a new observation")
                         maskType:SVProgressHUDMaskTypeGradient];
    
    
    Observation *o = [Observation object];
    
    o.idPlease = @(needId);
    
    if (taxon) {
        o.taxon = taxon;
        o.taxonID = taxon.recordID;
        o.iconicTaxonName = taxon.iconicTaxonName;
        o.iconicTaxonID = taxon.iconicTaxonID;
        o.speciesGuess = taxon.defaultName;
    }
    
    
    if (self.assetURL) {
        ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
        [lib assetForURL:self.assetURL
             resultBlock:^(ALAsset *asset) {
                 [self saveObservation:o withAssets:@[ asset ]];
             } failureBlock:^(NSError *error) {
                 [SVProgressHUD showErrorWithStatus:error.localizedDescription];
             }];
        
    } else if (self.assets && self.assets.count > 0) {
        [self saveObservation:o withAssets:self.assets];
    }
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
                                                            
                                                            [self configureCategories];
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
