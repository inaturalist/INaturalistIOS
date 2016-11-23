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
#import "LoginController.h"
#import "ObsEditV2ViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "User.h"
#import "NSFileManager+INaturalist.h"
#import "ExploreUpdateRealm.h"
#import "NewsPagerViewController.h"

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
static char TAXON_ASSOCIATED_KEY;
static char PROJECT_ASSOCIATED_KEY;

@interface INatUITabBarController () <UITabBarControllerDelegate, QBImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ObservationDetailViewControllerDelegate, UIAlertViewDelegate, RKObjectLoaderDelegate, RKRequestDelegate> {
    INatTooltipView *makeFirstObsTooltip;
    UIAlertView *authAlertView;
}

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleUserSavedObservationNotification:) 
                                                 name:INatUserSavedObservationNotification 
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
    
    // don't allow the user to re-order the items in the tab bar
    self.customizableViewControllers = nil;
    
    [self setUpdatesBadge];
}

- (void)dealloc {
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelRequestsWithDelegate:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if ([makeFirstObsTooltip superview]) {
        [makeFirstObsTooltip hideAnimated:NO];
    }
}


- (void)triggerNewObservationFlowForTaxon:(Taxon *)taxon project:(Project *)project {
    
    // check for free disk space
    if ([NSFileManager freeDiskSpaceMB] < 100) {
        // less than 100MB of free space
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You're running low on iPhone disk space!", nil)
                                    message:NSLocalizedString(@"We don't have enough room to make new observations!", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
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
        
        //[self noPhotoTaxon:taxon project:project];
        return;

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
        if (appDelegate.loginController.fetchMe.observationsCount.integerValue == 0) {
            if (![[NSUserDefaults standardUserDefaults] boolForKey:HasMadeAnObservationKey] && ![Observation hasAtLeastOneEntity]) {
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
    
    // ugly but how else to get the frame of a UITabBarItem?
    CGPoint origin;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        origin = CGPointMake(self.view.bounds.size.width * 3.0 / 7.0,
                             self.view.bounds.size.height - self.tabBar.frame.size.height - 5);
    } else {
        origin = CGPointMake(self.view.bounds.size.width / 2,
                             self.view.bounds.size.height - self.tabBar.frame.size.height - 5);
        
    }
    makeFirstObsTooltip = [[INatTooltipView alloc] initWithTargetPoint:origin
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
    
    NSDate *now = [NSDate date];
    o.localCreatedAt = now;

    // photoless observation defaults to now
    o.observedOn = now;
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
    
    ObsEditV2ViewController *confirmObs = [[ObsEditV2ViewController alloc] initWithNibName:nil bundle:nil];
    confirmObs.observation = o;
    confirmObs.shouldContinueUpdatingLocation = YES;
    confirmObs.isMakingNewObservation = YES;

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

#pragma mark badging

- (void)setUpdatesBadge {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    User *me = [appDelegate.loginController fetchMe];
    if (me) {
        NSPredicate *myNewPredicate = [NSPredicate predicateWithFormat:@"viewed == false and resourceOwnerId == %ld",
                                     (unsigned long)me.recordID.integerValue];
        
        RLMResults *myNewResults = [ExploreUpdateRealm objectsWithPredicate:myNewPredicate];
        UINavigationController *activity = [self.viewControllers objectAtIndex:1];
        
        if ([myNewResults count] > 0) {
            activity.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (unsigned long)[myNewResults count]];
        } else {
            activity.tabBarItem.badgeValue = nil;
        }
    }
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

- (void)userSignedIn {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.selectedViewController.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    User *user = appDelegate.loginController.fetchMe;
    if (user.observationsCount.integerValue > 0) {
        // user has made an observation
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HasMadeAnObservationKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [makeFirstObsTooltip hideAnimated:NO];
    }
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
