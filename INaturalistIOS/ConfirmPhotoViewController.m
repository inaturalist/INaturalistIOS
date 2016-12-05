//
//  ConfirmPhotoViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <FontAwesomeKit/FAKFontAwesome.h>
#import <Photos/Photos.h>

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
#import "Observation.h"
#import "Observation+AddAssets.h"
#import "Analytics.h"
#import "Project.h"
#import "ProjectObservation.h"
#import "ObsEditV2ViewController.h"
#import "UIColor+INaturalist.h"
#import "INaturalistAppDelegate+TransitionAnimators.h"

#define CHICLETWIDTH 100.0f
#define CHICLETHEIGHT 98.0f
#define CHICLETPADDING 2.0

@interface ConfirmPhotoViewController () <ObservationDetailViewControllerDelegate, TaxaSearchViewControllerDelegate> {
    PHPhotoLibrary *phLib;
    UIButton *retake, *confirm;
}
@property NSArray *iconicTaxa;
@property RKObjectLoader *taxaLoader;
@end

@implementation ConfirmPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.confirmFollowUpAction) {
        __weak typeof(self) weakSelf = self;
        self.confirmFollowUpAction = ^(NSArray *confirmedAssets){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            // go straight to making the observation
            Observation *o = [Observation object];
            o.localCreatedAt = [NSDate date];
            
            if (weakSelf.taxon) {
                o.taxon = weakSelf.taxon;
                o.speciesGuess = weakSelf.taxon.defaultName ?: weakSelf.taxon.name;
            }
            
            if (weakSelf.project) {
                ProjectObservation *po = [ProjectObservation object];
                po.observation = o;
                po.project = weakSelf.project;
            }
            
            [o addAssets:confirmedAssets];
            
            ObsEditV2ViewController *editObs = [[ObsEditV2ViewController alloc] initWithNibName:nil bundle:nil];
            editObs.observation = o;
            editObs.shouldContinueUpdatingLocation = strongSelf.shouldContinueUpdatingLocation;
            editObs.isMakingNewObservation = YES;
            
            // for sizzle
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            [weakSelf.navigationController setDelegate:appDelegate];
            
            [weakSelf.navigationController setNavigationBarHidden:NO animated:YES];
            [weakSelf.navigationController pushViewController:editObs animated:YES];
        };
    }
    
    phLib = [PHPhotoLibrary sharedPhotoLibrary];
    
    self.multiImageView = ({
        MultiImageView *iv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.borderColor = [UIColor blackColor];
        
        iv;
    });
    [self.view addSubview:self.multiImageView];
    
    retake = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        button.backgroundColor = [UIColor grayColor];
        
        button.layer.borderColor = [UIColor blackColor].CGColor;
        button.layer.borderWidth = 0.5f;
        
        [button setTitle:NSLocalizedString(@"RETAKE", @"Retake a photo")
                forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        
        
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
        button.backgroundColor = [UIColor inatGreen];
        
        button.layer.borderColor = [UIColor blackColor].CGColor;
        button.layer.borderWidth = 0.5f;
        
        [button setTitle:NSLocalizedString(@"NEXT", @"Confirm a new photo")
                forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        
        [button addTarget:self
                   action:@selector(confirm)
         forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:confirm];
    
    NSDictionary *views = @{
                            @"image": self.multiImageView,
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
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[image]-0-[confirm(==48)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[image]-0-[retake(==48)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
}

- (void)confirm {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationConfirmPhotos];
    
    // this can take a moment, so hide the retake/confirm buttons
    confirm.hidden = YES;
    retake.hidden = YES;
    
    if (self.image) {
        // we need to save to the Photos library
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = NSLocalizedString(@"Saving new photo...", @"status while saving your image");
        hud.removeFromSuperViewOnHide = YES;
        hud.dimBackground = YES;
        
        // embed geo
        CLLocationManager *loc = [[CLLocationManager alloc] init];
        
        [phLib performChanges:^{
            PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImage:self.image];
            if (loc.location) {
                request.location = loc.location;
            }
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            if (error) {
                [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving image: %@",
                                                    error.localizedDescription]];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error Saving Image", @"image save error title")
                                                                               message:error.localizedDescription
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                if (success) {
                    self.confirmFollowUpAction( @[ self.image ]);
                }
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
        self.multiImageView.assets = @[ self.image ];
    } else if (self.assets && self.assets.count > 0) {
        self.multiImageView.assets = self.assets;
        self.multiImageView.hidden = NO;
    }
}

- (void)dealloc {
    [[RKClient sharedClient].requestQueue cancelRequest:self.taxaLoader];
}

#pragma mark - ObservationDetailViewController delegate

- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationSaveObservation];
    NSError *saveError;
    [[Observation managedObjectContext] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving observation: %@",
                                            saveError.localizedDescription]];
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
