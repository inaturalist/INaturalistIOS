//
//  ConfirmPhotoViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

@import Photos;

#import <MBProgressHUD/MBProgressHUD.h>
#import <CoreLocation/CoreLocation.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <FontAwesomeKit/FAKFontAwesome.h>
#import <M13ProgressSuite/M13ProgressViewPie.h>

#import "ConfirmPhotoViewController.h"
#import "ImageStore.h"
#import "MultiImageView.h"
#import "TaxaSearchViewController.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"
#import "ObsEditV2ViewController.h"
#import "UIColor+INaturalist.h"
#import "INaturalistAppDelegate.h"
#import "CLLocation+EXIFGPSDictionary.h"
#import "UIImage+INaturalist.h"
#import "NSData+INaturalist.h"
#import "UIViewController+INaturalist.h"
#import "ExploreObservationRealm.h"

#define CHICLETWIDTH 100.0f
#define CHICLETHEIGHT 98.0f
#define CHICLETPADDING 2.0

@interface ConfirmPhotoViewController () {
    UIButton *retake, *confirm;
}
@property NSMutableArray *downloadedImages;
@property (copy) CLLocation *obsLocation;
@property (atomic, copy) NSDate *obsDate;
@end

@implementation ConfirmPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
        
    self.downloadedImages = [NSMutableArray array];
    
    if (!self.confirmFollowUpAction) {
        __weak typeof(self) weakSelf = self;
        self.confirmFollowUpAction = ^(NSArray *confirmedImages){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            // go straight to making the observation
            ExploreObservationRealm *o = [[ExploreObservationRealm alloc] init];
            o.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
            o.timeCreated = [NSDate date];
            o.timeSynced = nil;
            o.timeUpdatedLocally = [NSDate date];
            
            if (strongSelf.obsLocation) {
                o.latitude = strongSelf.obsLocation.coordinate.latitude;
                o.longitude = strongSelf.obsLocation.coordinate.longitude;
                o.privatePositionalAccuracy = strongSelf.obsLocation.horizontalAccuracy;
            }
            
            if (strongSelf.obsDate) {
                o.timeObserved = strongSelf.obsDate;
            }
            
            if (weakSelf.taxon) {
                o.taxon = weakSelf.taxon;
                o.speciesGuess = weakSelf.taxon.commonName ?: weakSelf.taxon.scientificName;
            }
            
            NSInteger idx = 0;
            for (UIImage *image in confirmedImages) {
                ExploreObservationPhotoRealm *op = [[ExploreObservationPhotoRealm alloc] init];
                op.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
                op.timeCreated = [NSDate date];
                op.timeSynced = nil;
                op.timeUpdatedLocally = [NSDate date];
                op.position = idx;
                op.photoKey = [[ImageStore sharedImageStore] createKey];
                
                NSError *saveError = nil;
                BOOL saved = [[ImageStore sharedImageStore] storeImage:image
                                                                forKey:op.photoKey
                                                                 error:&saveError];
                
                NSString *saveFailedTitle = NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg");
                NSString *saveFailedMsg = NSLocalizedString(@"Unknown error", @"Message body when we don't know the error");
                if (saveError) {
                    saveFailedTitle = saveError.localizedDescription;
                    saveFailedMsg = saveError.localizedRecoverySuggestion;
                }
                
                if (!saved) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveFailedTitle
                                                                                   message:saveFailedMsg
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil]];
                    [weakSelf presentViewController:alert animated:YES completion:nil];
                    
                    return;
                } else {
                    // TODO: localUpdatedAt in obs photos in realm
                    // op.localUpdatedAt = [NSDate date];
                    
                    [o.observationPhotos addObject:op];
                }
                
                idx++;
            }
            
            ObsEditV2ViewController *editObs = [[ObsEditV2ViewController alloc] initWithNibName:nil bundle:nil];
            editObs.standaloneObservation = o;
            editObs.shouldContinueUpdatingLocation = strongSelf.shouldContinueUpdatingLocation;
            editObs.isMakingNewObservation = YES;
                        
            [strongSelf.navigationController setNavigationBarHidden:NO animated:YES];
            [strongSelf.navigationController pushViewController:editObs animated:YES];
        };
    }
        
    self.multiImageView = ({
        MultiImageView *iv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.borderColor = [UIColor lightGrayColor];
        iv.pieBorderWidth = 4.0f;
        iv.pieColor = [UIColor lightGrayColor];
        
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
        
        button.enabled = NO;
        
        button;
    });
    [self.view addSubview:confirm];
    
    UILayoutGuide *safeGuide = [self inat_safeLayoutGuide];

    // horizontal
    [self.multiImageView.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [self.multiImageView.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    
    [retake.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [retake.trailingAnchor constraintEqualToAnchor:confirm.leadingAnchor].active = YES;
    [confirm.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    
    [retake.widthAnchor constraintEqualToAnchor:confirm.widthAnchor].active = YES;
    
    // vertical
    [self.multiImageView.topAnchor constraintEqualToAnchor:safeGuide.topAnchor].active = YES;
    [self.multiImageView.bottomAnchor constraintEqualToAnchor:confirm.topAnchor].active = YES;
    
    [confirm.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor].active = YES;
    [retake.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor].active = YES;
    
    [confirm.heightAnchor constraintEqualToConstant:48.0f].active = YES;
    [retake.heightAnchor constraintEqualToConstant:48.0f].active = YES;
}

- (void)confirm {
    // make sure we have permission to the photo library
    switch ([PHPhotoLibrary authorizationStatus]) {
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted: {
            // don't notify, don't try to save photo
            dispatch_async(dispatch_get_main_queue(), ^{
                [self moveOnToSaveNewObservation];
            });
            break;
        }
        case PHAuthorizationStatusNotDetermined:
            // ask permission
            [self requestPhotoLibraryPermission];
            break;
        case PHAuthorizationStatusAuthorized: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self savePhotoAndMoveOn];
            });
            break;
        }
        default:
            break;
    }
}

- (void)requestPhotoLibraryPermission {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        [[Analytics sharedClient] event:kAnalyticsEventPhotoLibraryPermissionsChanged
                         withProperties:@{
                                          @"Via": NSStringFromClass(self.class),
                                          @"NewValue": @(status),
                                          }];
        switch (status) {
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusRestricted:
            case PHAuthorizationStatusNotDetermined: {
                // don't notify, don't try to save photo
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self moveOnToSaveNewObservation];
                });
                break;
            }
            case PHAuthorizationStatusAuthorized: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self savePhotoAndMoveOn];
                });
                break;
            }
            default:
                break;
        }
    }];
    
}

- (void)moveOnToSaveNewObservation {
    // prefer to set the date/location to that of the first photo chosen
    for (PHAsset *asset in self.assets.reverseObjectEnumerator) {
        if (asset.location) {
            self.obsLocation = asset.location;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.confirmFollowUpAction(self.downloadedImages);
    });
}

- (void)savePhotoAndMoveOn {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationConfirmPhotos];
    
    // this can take a moment, so hide the retake/confirm buttons
    confirm.hidden = YES;
    retake.hidden = YES;
    
    [self moveOnToSaveNewObservation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.image) {
        self.multiImageView.imageCount = 1;
        UIImageView *iv = [[self.multiImageView imageViews] firstObject];
        iv.image = self.image;
        iv.contentMode = UIViewContentModeScaleAspectFit;
        [self.downloadedImages addObject:self.image];
        [self configureNextButton];
    }
    
    if (self.assets) {
        self.multiImageView.imageCount = self.assets.count;
        
        [self.assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            // fetch the asset, updating the progress bar
            // put the image in the accompanying imageview
            UIImageView *imageView = self.multiImageView.imageViews[idx];
            M13ProgressView *progressView = self.multiImageView.progressViews[idx];
            UIImageView *alertView = self.multiImageView.alertViews[idx];
            
            PHImageManager *manager = [PHImageManager defaultManager];
            
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.synchronous = NO;
            options.networkAccessAllowed = YES;
            options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressView.hidden = NO;
                    [progressView setProgress:progress animated:YES];
                });
            };

            [manager requestImageForAsset:asset
                               targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight)
                              contentMode:PHImageContentModeAspectFill
                                  options:options
                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                
                if ([info valueForKey:PHImageErrorKey] != nil) {
                    NSError *error = [info valueForKey:PHImageErrorKey];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        alertView.hidden = NO;
                        progressView.hidden = YES;
                    });
                } else if (![[info valueForKey:PHImageResultIsDegradedKey] boolValue]) {
                    // we are not degraded
                    [self.downloadedImages addObject:result];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressView.hidden = YES;
                        alertView.hidden = YES;
                        imageView.image = result;
                        [self configureNextButton];
                    });
                }
            }];
            
            // also request the original exif date
            PHContentEditingInputRequestOptions *editOptions = [[PHContentEditingInputRequestOptions alloc] init];
            editOptions.networkAccessAllowed = YES;

            [asset requestContentEditingInputWithOptions:editOptions
                                      completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                CIImage *image = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
                NSDictionary *exif = [image.properties valueForKey:@"{Exif}"];
                if (exif) {
                    NSString *exifOriginalDateTimeString = [exif valueForKey:@"DateTimeOriginal"];
                    NSDate *exifOriginalDateTime = [[self exifDateFormatter] dateFromString:exifOriginalDateTimeString];
                    if (!self.obsDate && exifOriginalDateTime) {
                        self.obsDate = exifOriginalDateTime;
                    }
                }
            }];

        }];
        
    }
}

- (NSDateFormatter *)exifDateFormatter {
    static NSDateFormatter *_df = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _df = [[NSDateFormatter alloc] init];
        _df.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        [_df setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    });
    return _df;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];
    
}

- (void)configureNextButton {
    if (self.downloadedImages.count == self.assets.count) {
        confirm.enabled = YES;
    } else {
        confirm.enabled = NO;
    }
}

@end
