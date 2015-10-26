//
//  INatUITabBarController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <QBImagePickerController/QBImagePickerController.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <AVFoundation/AVFoundation.h>
#import <BlocksKit+UIKit.h>
#import <TapkuLibrary/TapkuLibrary.h>
#import <objc/runtime.h>

#import "INatUITabBarController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "INatWebController.h"
#import "ObservationDetailViewController.h"
#import "ConfirmPhotoViewController.h"
#import "UIColor+INaturalist.h"
#import "ObsCameraOverlay.h"
#import "Taxon.h"
#import "INatTooltipView.h"
#import "Analytics.h"
#import "ProjectObservation.h"
#import "Project.h"
#import "SignupSplashViewController.h"
#import "LoginController.h"
#import "ConfirmObservationViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"

#define EXPLORE_TAB_INDEX   0
#define OBSERVE_TAB_INDEX   1
#define ME_TAB_INDEX        2

typedef NS_ENUM(NSInteger, INatPhotoSource) {
    INatPhotoSourceCamera,
    INatPhotoSourcePhotos
};

static NSString *HasMadeAnObservationKey = @"hasMadeAnObservation";
static char TAXON_ASSOCIATED_KEY;
static char PROJECT_ASSOCIATED_KEY;

@interface INatUITabBarController () <UITabBarControllerDelegate, QBImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ObservationDetailViewControllerDelegate, UIAlertViewDelegate, RKObjectLoaderDelegate, RKRequestDelegate> {
    INatTooltipView *makeFirstObsTooltip;
    UIAlertView *authAlertView;
}

@end

@implementation INatUITabBarController

- (void)viewDidLoad
{
    [self setObservationsTabBadge];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleUserSavedObservationNotification:) 
                                                 name:INatUserSavedObservationNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userSignedIn)
                                                 name:kUserLoggedInNotificationName
                                               object:nil];
        
    // tab bar delegate to intercept selection of the "observe" tab
    self.delegate = self;
    
    // configure camera VC
    FAKIcon *cameraOutline = [FAKIonIcons iosCameraOutlineIconWithSize:45];
    [cameraOutline addAttribute:NSForegroundColorAttributeName value:[UIColor inatInactiveGreyTint]];
    UIImage *cameraImg = [[cameraOutline imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    ((UIViewController *)[self.viewControllers objectAtIndex:OBSERVE_TAB_INDEX]).tabBarItem.image = cameraImg;
    ((UIViewController *)[self.viewControllers objectAtIndex:OBSERVE_TAB_INDEX]).tabBarItem.title = NSLocalizedString(@"Observe", @"Title for New Observation Tab Bar Button");
    
    // make the delegate call to make sure our side effects execute
    if ([self.delegate tabBarController:self shouldSelectViewController:[self viewControllers][ME_TAB_INDEX]]) {
        // Me tab
        self.selectedIndex = ME_TAB_INDEX;
    }
        
    [super viewDidLoad];
}

- (void)dealloc {
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelRequestsWithDelegate:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    BOOL mustRelocateTooltip = NO;
    if ([makeFirstObsTooltip superview]) {
        mustRelocateTooltip = YES;
        [makeFirstObsTooltip hideAnimated:NO];
    }
    
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                                     if (mustRelocateTooltip) {
                                         [self makeAndShowFirstObsTooltip];
                                     }
                                 }];
}


- (void)triggerNewObservationFlowForTaxon:(Taxon *)taxon project:(Project *)project {
    
    // check for access to assets library
    ALAuthorizationStatus alAuthStatus = [ALAssetsLibrary authorizationStatus];
    switch (alAuthStatus) {
        case ALAuthorizationStatusDenied:
        case ALAuthorizationStatusRestricted:
            [self presentAuthAlertForSource:INatPhotoSourcePhotos];
            return;
            break;
        case ALAuthorizationStatusAuthorized:
        case ALAuthorizationStatusNotDetermined:
        default:
            // continue
            break;
    }
    
    // check for access to camera
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self newObservationForTaxon:taxon project:project];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentAuthAlertForSource:INatPhotoSourceCamera];
            });
        }
    }];
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
    
    authAlertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                               message:alertMsg
                                              delegate:self
                                     cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                     otherButtonTitles:nil];
    
    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings) {
        NSString *settingsButtonTitle = NSLocalizedString(@"Settings",
                                                          @"The name of the iOS Settings app, used in an alert button that will launch Settings.");
        [authAlertView addButtonWithTitle:settingsButtonTitle];
    }
    [authAlertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == authAlertView && buttonIndex == 1) {
        BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
        if (canOpenSettings) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (void)newObservationForTaxon:(Taxon *)taxon project:(Project *)project {

    if (![[NSUserDefaults standardUserDefaults] boolForKey:HasMadeAnObservationKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HasMadeAnObservationKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [makeFirstObsTooltip hideAnimated:YES];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.delegate = self;
        picker.allowsEditing = NO;
        picker.showsCameraControls = NO;
        picker.cameraViewTransform = CGAffineTransformMakeTranslation(0, 50);
        
        if (taxon) {
            objc_setAssociatedObject(picker, &TAXON_ASSOCIATED_KEY, taxon, OBJC_ASSOCIATION_RETAIN);
        }
        
        if (project) {
            objc_setAssociatedObject(picker, &PROJECT_ASSOCIATED_KEY, project, OBJC_ASSOCIATION_RETAIN);
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
            [weakSelf noPhotoTaxon:taxon project:project];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [overlay.shutter bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationShutter];
            [picker takePicture];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [overlay.library bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationLibraryStart];
            [weakSelf openLibraryTaxon:taxon project:project];
        } forControlEvents:UIControlEventTouchUpInside];
        
        picker.cameraOverlayView = overlay;
        
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationLibraryStart];
        
        // no camera available
        QBImagePickerController *imagePickerController = [[QBImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.allowsMultipleSelection = YES;
        imagePickerController.maximumNumberOfSelection = 4;     // arbitrary
        imagePickerController.showsCancelButton = NO;           // so we get a back button
        imagePickerController.groupTypes = @[
                                             @(ALAssetsGroupSavedPhotos),
                                             @(ALAssetsGroupAlbum)
                                             ];
        
        if (taxon) {
            objc_setAssociatedObject(imagePickerController, &TAXON_ASSOCIATED_KEY, taxon, OBJC_ASSOCIATION_RETAIN);
        }
        
        if (project) {
            objc_setAssociatedObject(imagePickerController, &PROJECT_ASSOCIATED_KEY, project, OBJC_ASSOCIATION_RETAIN);
        }
        
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
        [self presentViewController:nav animated:YES completion:nil];
    }
    
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    // intercept selection of the "observe" tab
    if ([tabBarController.viewControllers indexOfObject:viewController] == OBSERVE_TAB_INDEX) {
        
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationStart withProperties:@{ @"From": @"TabBar" }];

        [self triggerNewObservationFlowForTaxon:nil project:nil];
        
        return NO;
    } else if ([tabBarController.viewControllers indexOfObject:viewController] == ME_TAB_INDEX) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (![appDelegate.loginController isLoggedIn] && ![[NSUserDefaults standardUserDefaults] boolForKey:HasMadeAnObservationKey]) {
            if (![Observation hasAtLeastOneEntity]) {
                // show the "make your first" tooltip
                [self makeAndShowFirstObsTooltip];
            }
        }
    } else {
        [makeFirstObsTooltip hideAnimated:NO];
    }
    
    return YES;
}

#pragma mark - Tooltip Helper

- (void)makeAndShowFirstObsTooltip {
    if ([makeFirstObsTooltip superview]) {
        [makeFirstObsTooltip hideAnimated:NO];
    }
    
    NSString *firstObsText = NSLocalizedString(@"Make your first observation", @"Tooltip prompting users to make their first observation");
    makeFirstObsTooltip = [[INatTooltipView alloc] initWithTargetBarButtonItem:self.tabBar.items[OBSERVE_TAB_INDEX]
                                                                      hostView:self.view
                                                                   tooltipText:firstObsText
                                                                arrowDirection:JDFTooltipViewArrowDirectionDown
                                                                         width:200];
    makeFirstObsTooltip.tooltipBackgroundColour = [UIColor inatTint];
    makeFirstObsTooltip.shouldCenter = YES;
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf.selectedIndex == ME_TAB_INDEX)
            [makeFirstObsTooltip show];
    });
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.image = [info valueForKey:UIImagePickerControllerOriginalImage];
    confirm.metadata = [info valueForKey:UIImagePickerControllerMediaMetadata];
    confirm.shouldContinueUpdatingLocation = YES;
    
    Taxon *taxon = objc_getAssociatedObject(picker, &TAXON_ASSOCIATED_KEY);
    if (taxon) {
        confirm.taxon = taxon;
    }
    Project *project = objc_getAssociatedObject(picker, &PROJECT_ASSOCIATED_KEY);
    if (project) {
        confirm.project = project;
    }

    [picker pushViewController:confirm animated:NO];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Add New Observation methods

- (void)openLibraryTaxon:(Taxon *)taxon project:(Project *)project {
    // qbimagepicker for library multi-select
    QBImagePickerController *imagePickerController = [[QBImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.maximumNumberOfSelection = 4;     // arbitrary
    imagePickerController.showsCancelButton = NO;           // so we get a back button
    imagePickerController.groupTypes = @[
                                         @(ALAssetsGroupSavedPhotos),
                                         @(ALAssetsGroupAlbum)
                                         ];
    
    if (taxon) {
        objc_setAssociatedObject(imagePickerController, &TAXON_ASSOCIATED_KEY, taxon, OBJC_ASSOCIATION_RETAIN);
    }
    
    if (project) {
        objc_setAssociatedObject(imagePickerController, &PROJECT_ASSOCIATED_KEY, project, OBJC_ASSOCIATION_RETAIN);
    }
    
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav pushViewController:imagePickerController animated:YES];
    [nav setNavigationBarHidden:NO animated:YES];
    imagePickerController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"Next button when picking photos for a new observation")
                                                                                               style:UIBarButtonItemStylePlain
                                                                                              target:imagePickerController
                                                                                              action:@selector(done:)];
}

- (void)noPhotoTaxon:(Taxon *)taxon project:(Project *)project {
    Observation *o = [Observation object];
    
    // photoless observation defaults to now
    o.observedOn = [NSDate date];
    o.localObservedOn = o.observedOn;
    o.observedOnString = [Observation.jsDateFormatter stringFromDate:o.localObservedOn];
    
    if (taxon) {
        o.taxon = taxon;
        o.speciesGuess = taxon.defaultName;
    }
    
    if (project) {
        ProjectObservation *po = [ProjectObservation object];
        po.observation = o;
        po.project = project;
    }
    
    ConfirmObservationViewController *confirmObs = [[ConfirmObservationViewController alloc] initWithNibName:nil bundle:nil];
    confirmObs.observation = o;
    confirmObs.shouldContinueUpdatingLocation = YES;
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav setNavigationBarHidden:NO animated:YES];
    [nav pushViewController:confirmObs animated:YES];
}

#pragma mark - ObservationDetailViewController delegate

- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationSaveObservation];
    NSError *saveError;
    [[Observation managedObjectContext] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error saving new obs: %@",
                                            saveError.localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save Error", nil)
                                    message:saveError.localizedDescription
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)observationDetailViewControllerDidCancel:(ObservationDetailViewController *)controller {
    [controller.navigationController setToolbarHidden:YES animated:NO];

    @try {
        [controller.observation destroy];
    } @catch (NSException *exception) {
        if ([exception.name isEqualToString:NSObjectInaccessibleException]) {
            // if observation has been deleted or is otherwise inaccessible, do nothing
            return;
        }
    }
}

#pragma mark - QBImagePicker delegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationLibraryPicked
                     withProperties:@{ @"numPics": @(assets.count) }];
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.assets = assets;
    
    Taxon *taxon = objc_getAssociatedObject(imagePickerController, &TAXON_ASSOCIATED_KEY);
    if (taxon) {
        confirm.taxon = taxon;
    }
    
    Project *project = objc_getAssociatedObject(imagePickerController, &PROJECT_ASSOCIATED_KEY);
    if (project) {
        confirm.project = project;
    }

    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav pushViewController:confirm animated:NO];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark lifecycle

// make sure view controllers in the tabs can autorotate
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (NSUInteger)supportedInterfaceOrientations
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

- (void)handleUserSavedObservationNotification:(NSNotification *)notification
{
    [self setObservationsTabBadge];
}

- (void)setObservationsTabBadge {
    NSInteger theCount = [[Observation needingUpload] count];
    theCount += [Observation deletedRecordCount];
    
    UITabBarItem *item = [self.tabBar.items objectAtIndex:ME_TAB_INDEX];
    if (theCount > 0) {
        item.badgeValue = [NSString stringWithFormat:@"%ld", (long)theCount];
    } else {
        item.badgeValue = nil;
    }
    
    // request permission to badge the app
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:theCount];
}

- (void)userSignedIn {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.selectedViewController.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [makeFirstObsTooltip hideAnimated:NO];
}

#pragma mark - RKObjectLoader & RKRequest delegates

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // do nothing
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    // update timestamps on taxa objects
    NSDate *now = [NSDate date];
    [objects enumerateObjectsUsingBlock:^(INatModel *o,
                                          NSUInteger idx,
                                          BOOL *stop) {
        [o setSyncedAt:now];
    }];
    
    NSError *saveError = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error saving store: %@",
                                            saveError.localizedDescription]];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    // do nothing
}

@end
