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
#import <BlocksKit/BlocksKit+UIKit.h>
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
#import "CategorizeViewController.h"
#import "Observation.h"
#import "Observation+AddAssets.h"
#import "Analytics.h"
#import "Project.h"
#import "ProjectObservation.h"

#define CHICLETWIDTH 100.0f
#define CHICLETHEIGHT 98.0f
#define CHICLETPADDING 2.0

@interface ConfirmPhotoViewController () <ObservationDetailViewControllerDelegate, TaxaSearchViewControllerDelegate> {
    MultiImageView *multiImageView;
    ALAssetsLibrary *lib;
    UIButton *retake, *confirm;
}
@property NSArray *iconicTaxa;
@property RKObjectLoader *taxaLoader;
@end

@implementation ConfirmPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // make sure we have some local iconic taxa before we try to categorize
    // if we don't have any, try to load remotely
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kInatCategorizeNewObsPrefKey]) {
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Taxon"];
        request.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"defaultName" ascending:YES] ];
        [request setPredicate:[NSPredicate predicateWithFormat:@"isIconic == YES"]];
        
        NSError *fetchError;
        self.iconicTaxa = [[NSManagedObjectContext defaultContext] executeFetchRequest:request
                                                                                 error:&fetchError];

        if (self.iconicTaxa.count == 0) {
            [self loadRemoteIconicTaxa];
        }
        
    }
    
    if (!self.confirmFollowUpAction) {
        __weak typeof(self) weakSelf = self;
        self.confirmFollowUpAction = ^(NSArray *confirmedAssets){
            
            // Don't display categorize screen option, for now.
            BOOL shouldCheckForCategorize = NO;
            if (shouldCheckForCategorize && [[NSUserDefaults standardUserDefaults] boolForKey:kInatCategorizeNewObsPrefKey] && weakSelf.iconicTaxa.count > 0 && !weakSelf.taxon) {
                // categorize the new observation before making it
                CategorizeViewController *categorize = [[CategorizeViewController alloc] initWithNibName:nil bundle:nil];
                categorize.assets = confirmedAssets;
                if (weakSelf.project) {
                    categorize.project = weakSelf.project;
                }
                categorize.shouldContinueUpdatingLocation = weakSelf.shouldContinueUpdatingLocation;
                [weakSelf transitionToCategorize:categorize];
            } else {
                // go straight to making the observation
                Observation *o = [Observation object];
                
                if (weakSelf.taxon) {
                    o.taxon = weakSelf.taxon;
                    o.speciesGuess = weakSelf.taxon.defaultName ?: weakSelf.taxon.name;
                }
                
                if (weakSelf.project) {
                    ProjectObservation *po = [ProjectObservation object];
                    po.observation = o;
                    po.project = weakSelf.project;
                }
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                ObservationDetailViewController *detail = [storyboard instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
                
                detail.delegate = weakSelf;
                detail.shouldShowBigSaveButton = YES;
                
                [o addAssets:confirmedAssets];
                detail.observation = o;
                
                [weakSelf.navigationController setNavigationBarHidden:NO animated:YES];
                [weakSelf.navigationController pushViewController:detail animated:YES];
                
                if (weakSelf.shouldContinueUpdatingLocation)
                    [detail startUpdatingLocation];
            }
        };
    }
    
    lib = [[ALAssetsLibrary alloc] init];
    
    multiImageView = ({
        MultiImageView *iv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.borderColor = [UIColor blackColor];
        
        iv;
    });
    [self.view addSubview:multiImageView];
    
    retake = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        button.backgroundColor = [UIColor blackColor];
        button.layer.borderColor = [UIColor grayColor].CGColor;
        button.layer.borderWidth = 1.0f;
        
        [button setTitle:NSLocalizedString(@"Retake", @"Retake a photo")
                forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        __weak typeof(self)weakSelf = self;
        [button bk_addEventHandler:^(id sender) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationRetakePhotos];
            [strongSelf.navigationController popViewControllerAnimated:YES];
            if (strongSelf.assets)
                [strongSelf.navigationController setNavigationBarHidden:NO];
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:retake];
    
    confirm = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        button.backgroundColor = [UIColor blackColor];
        
        button.layer.borderColor = [UIColor grayColor].CGColor;
        button.layer.borderWidth = 1.0f;
        
        [button setTitle:NSLocalizedString(@"Confirm", @"Confirm a new photo")
                forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [button addTarget:self
                   action:@selector(confirm)
         forControlEvents:UIControlEventTouchUpInside];

        button;
    });
    [self.view addSubview:confirm];
    
    NSDictionary *views = @{
                            @"image": multiImageView,
                            @"confirm": confirm,
                            @"retake": retake,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[image]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[retake]-0-[confirm(==retake)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[image]-0-[confirm(==60)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[image]-0-[retake(==60)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
}

- (void)confirm {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationConfirmPhotos];
    
    if (self.image) {
        // we need to save to the AssetsLibrary...
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving new photo...", @"status while saving your image")];
        // embed geo
        CLLocationManager *loc = [[CLLocationManager alloc] init];
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
        
        [lib writeImageToSavedPhotosAlbum:self.image.CGImage
                                 metadata:mutableMetadata
                          completionBlock:^(NSURL *newAssetUrl, NSError *error) {
                              if (error) {
                                  [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving image: %@",
                                                                      error.localizedDescription]];
                                  [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                              } else {
                                  [SVProgressHUD dismiss];
                                  
                                  [lib assetForURL:newAssetUrl
                                       resultBlock:^(ALAsset *asset) {
                                           // be defensive
                                           if (asset) {
                                               self.confirmFollowUpAction(@[ asset ]);
                                           } else {
                                               [[Analytics sharedClient] debugLog:@"error loading newly saved asset"];
                                               [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error using newly saved image!",
                                                                                                    @"Error message when we can't load a newly saved image")];
                                           }
                                           
                                       } failureBlock:^(NSError *error) {
                                           [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching asset: %@",
                                                                               error.localizedDescription]];
                                           [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                       }];
                                  
                              }
                          }];
    } else if (self.assets) {
        // can proceed directly to followup
        self.confirmFollowUpAction(self.assets);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    if (self.image) {
        multiImageView.images = @[ self.image ];
    } else if (self.assets && self.assets.count > 0) {
        NSArray *images = [[self.assets bk_map:^id(ALAsset *asset) {
            return [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
        }] bk_select:^BOOL(id obj) {
            // imageWithCGImage can return nil, which bk_map converts to NSNull
            return obj && obj != [NSNull null];
        }];
        multiImageView.images = images;
        multiImageView.hidden = NO;
    }
}

- (void)dealloc {
    [[RKClient sharedClient].requestQueue cancelRequest:self.taxaLoader];
}

- (void)transitionToCategorize:(CategorizeViewController *)categorizeVC {
    
    UINavigationController *nav = self.navigationController;
    [UIView animateWithDuration:0.1f
                     animations:^{
                         confirm.center = CGPointMake(confirm.center.x,
                                                      self.view.bounds.size.height + (confirm.frame.size.height / 2));
                         retake.center = CGPointMake(retake.center.x,
                                                     self.view.bounds.size.height + (retake.frame.size.height / 2));
                         multiImageView.frame = self.view.bounds;
                     } completion:^(BOOL finished) {
                         [nav pushViewController:categorizeVC animated:NO];
                         
                         confirm.center = CGPointMake(confirm.center.x,
                                                      self.view.bounds.size.height - (confirm.frame.size.height / 2));
                         retake.center = CGPointMake(retake.center.x,
                                                     self.view.bounds.size.height - (retake.frame.size.height / 2));
                         
                     }];
}

#pragma mark - ObservationDetailViewController delegate

- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationSaveObservation];
    NSError *saveError;
    [[Observation managedObjectContext] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving observation: %@",
                                            saveError.localizedDescription]];
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
    if (![[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined] ||
        ![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    self.taxaLoader = [[RKObjectManager sharedManager] loaderWithResourcePath:@"/taxa"];
    self.taxaLoader.objectMapping = [Taxon mapping];
    self.taxaLoader.onDidLoadObjects = ^(NSArray *objects) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
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
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving object store: %@",
                                                saveError.localizedDescription]];
            [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
            return;
        }
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Taxon"];
        request.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"defaultName" ascending:YES] ];
        [request setPredicate:[NSPredicate predicateWithFormat:@"isIconic == YES"]];
        
        NSError *fetchError;
        strongSelf.iconicTaxa = [[NSManagedObjectContext defaultContext] executeFetchRequest:request
                                                                                       error:&fetchError];
    };
    self.taxaLoader.onDidFailLoadWithError = ^(NSError *error) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error loading: %@",
                                            error.localizedDescription]];
    };
    self.taxaLoader.onDidFailLoadWithError = ^(NSError *error) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error loading: %@",
                                            error.localizedDescription]];
    };
    [[Analytics sharedClient] debugLog:@"Network - Load iconic taxa in confirm"];
    [self.taxaLoader sendAsynchronously];
}


@end
