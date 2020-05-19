//
//  INatUITabBarController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

@import FontAwesomeKit;
@import AVFoundation;
@import BlocksKit;
@import TapkuLibrary;
@import Photos;
@import Gallery;

#import "Gallery-Swift.h"

#import <objc/runtime.h>

#import "INatUITabBarController.h"
#import "INatWebController.h"
#import "ConfirmPhotoViewController.h"
#import "UIColor+INaturalist.h"
#import "ObsCameraOverlay.h"
#import "Taxon.h"
#import "INatTooltipView.h"
#import "Analytics.h"
#import "LoginController.h"
#import "ObsEditV2ViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "NSFileManager+INaturalist.h"
#import "ExploreUpdateRealm.h"
#import "NewsPagerViewController.h"
#import "ImageStore.h"
#import "ExploreUserRealm.h"
#import "ExploreTaxonRealm.h"
#import "ExploreObservationRealm.h"

#define EXPLORE_TAB_INDEX   0
#define NEWS_TAB_INDEX      1
#define OBSERVE_TAB_INDEX   2
#define ME_TAB_INDEX        3
#define PROJECTS_TAB_INDEX  4
#define GUIDES_TAB_INDEX    5

typedef NS_ENUM(NSInteger, INatPhotoSource) {
    INatPhotoSourceCamera,
    INatPhotoSourcePhotos
};

NSString *HasMadeAnObservationKey = @"hasMadeAnObservation";
static char TAXON_ID_ASSOCIATED_KEY;

@interface INatUITabBarController () <UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation INatUITabBarController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userSignedIn)
                                                     name:kUserLoggedInNotificationName
                                                   object:nil];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // tab bar delegate to intercept selection of the "observe" tab
    self.delegate = self;
    
    // configure camera VC
    FAKIcon *camera = [FAKIonIcons iosCameraIconWithSize:45];
    [camera addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
    UIImage *cameraImg = [[camera imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    ((UIViewController *)[self.viewControllers objectAtIndex:OBSERVE_TAB_INDEX]).tabBarItem.image = cameraImg;
    ((UIViewController *)[self.viewControllers objectAtIndex:OBSERVE_TAB_INDEX]).tabBarItem.title = NSLocalizedString(@"Observe", @"Title for New Observation Tab Bar Button");
    
    [self setSelectedIndex:ME_TAB_INDEX];
    
    // don't allow the user to re-order the items in the tab bar
    self.customizableViewControllers = nil;
}

- (void)triggerNewObservationFlowForTaxon:(Taxon *)taxon {
    
    // check for free disk space
    if ([NSFileManager freeDiskSpaceMB] < 100) {
        // less than 100MB of free space
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"You're running low on iPhone disk space!", nil)
                                                                       message:NSLocalizedString(@"We don't have enough room to make new observations!", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
        
    // check for access to camera
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self newObservationForTaxon:taxon];
            });
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            [self presentAuthAlertForSource:INatPhotoSourceCamera];
            break;
        case AVAuthorizationStatusNotDetermined:
        default:
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                [[Analytics sharedClient] event:kAnalyticsEventCameraPermissionsChanged
                                 withProperties:@{
                                                  @"Via": NSStringFromClass(self.class),
                                                  @"NewValue": @(granted),
                                                  }];
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self newObservationForTaxon:taxon];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentAuthAlertForSource:INatPhotoSourceCamera];
                    });
                }

            }];
            break;
    }
}

- (void)presentAuthAlertForSource:(INatPhotoSource)source {
    
    NSString *alertTitle, *alertMsg;
    switch (source) {
        case INatPhotoSourceCamera:
            alertTitle = NSLocalizedString(@"Cannot access camera", @"Alert title when we don't have permission to access camera.");
            alertMsg = NSLocalizedString(@"Please make sure iNaturalist is turned on in Settings > Privacy > Camera",
                                         @"Alert message when we don't have permission to access the camera.");
            break;
        case INatPhotoSourcePhotos:
        default:
            alertTitle = NSLocalizedString(@"Cannot access photos", @"Alert title when we don't have permission to access photos.");
            alertMsg = NSLocalizedString(@"Please make sure iNaturalist is turned on in Settings > Privacy > Photos",
                                         @"Alert message when we don't have permission to access the photo library.");
            break;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMsg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    BOOL canOpenSettings = (UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings) {
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"The name of the iOS Settings app")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                    [[UIApplication sharedApplication] openURL:url];
                                                }]];
    }
    
    if (self.presentedViewController) {
        [self.presentedViewController presentViewController:alert animated:YES completion:nil];
    } else {
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)newObservationForTaxon:(id <TaxonVisualization>)taxon {
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:HasMadeAnObservationKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HasMadeAnObservationKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.delegate = self;
        picker.allowsEditing = NO;
        picker.showsCameraControls = NO;
        
        if (taxon) {
            objc_setAssociatedObject(picker, &TAXON_ID_ASSOCIATED_KEY, @([taxon taxonId]), OBJC_ASSOCIATION_RETAIN);
        }
                
        ObsCameraOverlay *overlay = [[ObsCameraOverlay alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        overlay.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        [overlay configureFlashForMode:picker.cameraFlashMode];
        
        __weak typeof(self) weakSelf = self;
        
        [overlay.close bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationCancel];
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        } forControlEvents:UIControlEventTouchUpInside];
        
        // hide flash if it's not available for the default camera
        if (![UIImagePickerController isFlashAvailableForCameraDevice:picker.cameraDevice]) {
            overlay.flash.hidden = YES;
        }
        
        [overlay.flash bk_addEventHandler:^(id sender) {
            if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeAuto) {
                picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
            } else if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn) {
                picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
            } else if (picker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
                picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
            }
            [overlay configureFlashForMode:picker.cameraFlashMode];
        } forControlEvents:UIControlEventTouchUpInside];
        
        // hide camera selector unless both front and rear cameras are available
        if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ||
            ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            overlay.camera.hidden = YES;
        }
        
        [overlay.camera bk_addEventHandler:^(id sender) {
            if (picker.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
                picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            } else {
                picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
            // hide flash button if flash isn't available for the chosen camera
            overlay.flash.hidden = ![UIImagePickerController isFlashAvailableForCameraDevice:picker.cameraDevice];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [overlay.noPhoto bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationNoPhoto];
            [weakSelf noPhotoTaxon:taxon];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [overlay.shutter bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationShutter];
            [picker takePicture];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [overlay.library bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationLibraryStart];
            [weakSelf openLibraryTaxon:taxon];
        } forControlEvents:UIControlEventTouchUpInside];
        
        picker.cameraOverlayView = overlay;
        
        UIScreen *screen = [UIScreen mainScreen];
        CGFloat cameraAspectRatio = 4.0 / 3.0;
        CGFloat cameraPreviewHeight = screen.nativeBounds.size.width * cameraAspectRatio;
        CGFloat screenHeight = screen.nativeBounds.size.height;
        CGFloat transformHeight = (screenHeight-cameraPreviewHeight) / screen.nativeScale / 2.0f;
        
        picker.cameraViewTransform = CGAffineTransformMakeTranslation(0, transformHeight);
        [self presentViewController:picker animated:YES completion:nil];
        
    } else {
        
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationLibraryStart];
        
        // no camera available
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        if (taxon) {
            objc_setAssociatedObject(picker, &TAXON_ID_ASSOCIATED_KEY, @(taxon.taxonId), OBJC_ASSOCIATION_RETAIN);
        }
                
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    // intercept selection of the "observe" tab
    if ([tabBarController.viewControllers indexOfObject:viewController] == OBSERVE_TAB_INDEX) {
        
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationStart withProperties:@{ @"From": @"TabBar" }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self triggerNewObservationFlowForTaxon:nil];
        });
        
        return NO;
    }
    
    return YES;
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    if (!originalImage) {
        
        NSString *alertTitle = NSLocalizedString(@"Camera Problem", @"Title for failure to get a photo from photo picker or camera alert");
        NSString *alertMsg = NSLocalizedString(@"Couldn't load data for the selected photo. Please try again.", @"Please try again message, in an alert view, for when we can't get a photo from the camera/library.");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [picker presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.image = originalImage;
    confirm.metadata = [info valueForKey:UIImagePickerControllerMediaMetadata];
    
    BOOL selectedFromLibrary = NO;
    if (@available(iOS 11.0, *)) {
        if ([info valueForKey:UIImagePickerControllerPHAsset]) {
            PHAsset *asset = [info valueForKey:UIImagePickerControllerPHAsset];
            confirm.photoTakenLocation = asset.location;
            confirm.photoTakenDate = asset.creationDate;
            
            selectedFromLibrary = YES;
        }
    } else {
        if ([info valueForKey:UIImagePickerControllerReferenceURL]) {
            NSURL *assetURL = [info valueForKey:UIImagePickerControllerReferenceURL];
            PHFetchResult *assets = [PHAsset fetchAssetsWithALAssetURLs:@[ assetURL ] options:nil];
            PHAsset *asset = [assets firstObject];
            if (asset) {
                confirm.photoTakenLocation = asset.location;
                confirm.photoTakenDate = asset.creationDate;
                
                selectedFromLibrary = YES;
            }
        }
    }
    
    if (selectedFromLibrary) {
        confirm.shouldContinueUpdatingLocation = NO;
        confirm.isSelectingFromLibrary = YES;
    } else {
        confirm.shouldContinueUpdatingLocation = YES;
        confirm.isSelectingFromLibrary = NO;
    }
    
    NSNumber *taxonId = objc_getAssociatedObject(picker, &TAXON_ID_ASSOCIATED_KEY);
    if (taxonId && taxonId.integerValue != 0) {
        confirm.taxon = [ExploreTaxonRealm objectForPrimaryKey:taxonId];
    }
    
    [picker pushViewController:confirm animated:NO];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Add New Observation methods

- (void)openLibraryTaxon:(id <TaxonVisualization>)taxon {
    PHAuthorizationStatus phAuthStatus = [PHPhotoLibrary authorizationStatus];
    switch (phAuthStatus) {
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
            [self presentAuthAlertForSource:INatPhotoSourcePhotos];
            return;
            break;
        case PHAuthorizationStatusNotDetermined: {
            __weak typeof(self)weakSelf = self;
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                [[Analytics sharedClient] event:kAnalyticsEventPhotoLibraryPermissionsChanged
                                 withProperties:@{
                                                  @"Via": NSStringFromClass(weakSelf.class),
                                                  @"NewValue": @(status),
                                                  }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (status == PHAuthorizationStatusAuthorized) {
                        [weakSelf openLibraryTaxon:taxon];
                    } else {
                        [weakSelf presentAuthAlertForSource:INatPhotoSourcePhotos];
                    }
                });
            }];
            return;
            break;
        }
        case PHAuthorizationStatusAuthorized:
            // continue;
            break;
    }

    // select from photo library
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    if (taxon) {
        objc_setAssociatedObject(picker, &TAXON_ID_ASSOCIATED_KEY, @(taxon.taxonId), OBJC_ASSOCIATION_RETAIN);
    }
        
    UIViewController *presentedVC = self.presentedViewController;
    [presentedVC presentViewController:picker animated:YES completion:nil];
}


- (void)noPhotoTaxon:(id <TaxonVisualization>)taxon {
    ExploreObservationRealm *o = [[ExploreObservationRealm alloc] init];
    o.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
    o.timeCreated = [NSDate date];
    o.timeUpdatedLocally = [NSDate date];
    
    // photoless observation defaults to now
    o.timeObserved = [NSDate date];
    
    if (taxon) {
        ExploreTaxonRealm *etr = [ExploreTaxonRealm objectForPrimaryKey:@(taxon.taxonId)];
        if (etr) {
            o.taxon = etr;
        }
        o.speciesGuess = taxon.commonName ?: taxon.scientificName;
    }
        
    ObsEditV2ViewController *confirmObs = [[ObsEditV2ViewController alloc] initWithNibName:nil bundle:nil];
    confirmObs.standaloneObservation = o;
    confirmObs.shouldContinueUpdatingLocation = YES;
    confirmObs.isMakingNewObservation = YES;
    
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav setNavigationBarHidden:NO animated:YES];
    [nav pushViewController:confirmObs animated:YES];
}

#pragma mark lifecycle

// make sure view controllers in the tabs can autorotate
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([self.selectedViewController isKindOfClass:UINavigationController.class]) {
        UINavigationController *nc = (UINavigationController *)self.selectedViewController;
        return [nc.visibleViewController supportedInterfaceOrientations];
    } else if ([self.selectedViewController isKindOfClass:[UIAlertController class]]) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return [self.selectedViewController supportedInterfaceOrientations];
    }
}

- (void)userSignedIn {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.selectedViewController.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    if (me.observationsCount > 0) {
        // user has made an observation
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HasMadeAnObservationKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
