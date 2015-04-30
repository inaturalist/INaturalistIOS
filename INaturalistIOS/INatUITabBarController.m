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
#import <SVProgressHUD/SVProgressHUD.h>
#import <TapkuLibrary/TapkuLibrary.h>

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
#import "LoginViewController.h"
#import "Analytics.h"

static NSString *HasMadeAnObservationKey = @"hasMadeAnObservation";

@interface INatUITabBarController () <UITabBarControllerDelegate, QBImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ObservationDetailViewControllerDelegate> {
    INatTooltipView *makeFirstObsTooltip;
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
    FAKIcon *camera = [FAKIonIcons iosCameraIconWithSize:45];
    [camera addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    FAKIcon *cameraOutline = [FAKIonIcons iosCameraOutlineIconWithSize:45];
    [cameraOutline addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    UIImage *img = [[UIImage imageWithStackedIcons:@[camera, cameraOutline]
                                         imageSize:CGSizeMake(34,45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    ((UIViewController *)[self.viewControllers objectAtIndex:2]).tabBarItem.image = img;
    ((UIViewController *)[self.viewControllers objectAtIndex:2]).tabBarItem.title = NSLocalizedString(@"Observe", @"Title for New Observation Tab Bar Button");
    [((UIViewController *)[self.viewControllers objectAtIndex:2]).tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] }
                                                                                           forState:UIControlStateNormal];
    
    // make the delegate call to make sure our side effects execute
    if ([self.delegate tabBarController:self shouldSelectViewController:[self viewControllers][4]]) {
        // Me tab
        self.selectedIndex = 4;
    }
    
    // we'll use the iconic taxa during the new observation flow
    [self fetchIconicTaxa];
    
    
    // 7.1 and greater can handle translucent tab bars correctly
    [self.tabBar setTranslucent:SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.1")];
    
    [super viewDidLoad];
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

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    // intercept selection of the "observe" tab
    if ([tabBarController.viewControllers indexOfObject:viewController] == 2) {
        
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationStart];
        
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
            
            ObsCameraOverlay *overlay = [[ObsCameraOverlay alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            overlay.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
            [overlay configureFlashForMode:picker.cameraFlashMode];
            
            [overlay.close bk_addEventHandler:^(id sender) {
                [[Analytics sharedClient] event:kAnalyticsEventNewObservationCancel];
                [self dismissViewControllerAnimated:YES completion:nil];
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
                [self noPhoto];
            } forControlEvents:UIControlEventTouchUpInside];
            
            [overlay.shutter bk_addEventHandler:^(id sender) {
                [[Analytics sharedClient] event:kAnalyticsEventNewObservationShutter];
                [picker takePicture];
            } forControlEvents:UIControlEventTouchUpInside];
            
            [overlay.library bk_addEventHandler:^(id sender) {
                [[Analytics sharedClient] event:kAnalyticsEventNewObservationLibraryStart];
                [self openLibrary];
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
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
            [self presentViewController:nav animated:YES completion:nil];
        }
        
        
        return NO;
    } else if ([tabBarController.viewControllers indexOfObject:viewController] == 4) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:HasMadeAnObservationKey]) {
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
    makeFirstObsTooltip = [[INatTooltipView alloc] initWithTargetBarButtonItem:self.tabBar.items[2]
                                                                      hostView:self.view
                                                                   tooltipText:firstObsText
                                                                arrowDirection:JDFTooltipViewArrowDirectionDown
                                                                         width:200];
    makeFirstObsTooltip.tooltipBackgroundColour = [UIColor inatTint];
    makeFirstObsTooltip.shouldCenter = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.selectedIndex == 4)
            [makeFirstObsTooltip show];
    });
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.image = [info valueForKey:UIImagePickerControllerOriginalImage];
    confirm.metadata = [info valueForKey:UIImagePickerControllerMediaMetadata];
    confirm.shouldContinueUpdatingLocation = YES;
    [picker pushViewController:confirm animated:NO];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Add New Observation methods

- (void)openLibrary {
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
    
    
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav pushViewController:imagePickerController animated:YES];
    [nav setNavigationBarHidden:NO animated:YES];
    imagePickerController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"Next button when picking photos for a new observation")
                                                                                               style:UIBarButtonItemStylePlain
                                                                                              target:imagePickerController
                                                                                              action:@selector(done:)];
}

- (void)noPhoto {
    Observation *o = [Observation object];
    
    // photoless observation defaults to now
    o.observedOn = [NSDate date];
    o.localObservedOn = o.observedOn;
    o.observedOnString = [Observation.jsDateFormatter stringFromDate:o.localObservedOn];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ObservationDetailViewController *detail = [storyboard instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
    detail.observation = o;
    detail.shouldShowBigSaveButton = YES;
    detail.delegate = self;
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav setNavigationBarHidden:NO];
    [nav pushViewController:detail animated:YES];
}

#pragma mark - ObservationDetailViewController delegate

- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationSaveObservation];
    NSError *saveError;
    [[Observation managedObjectContext] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error saving new obs: %@",
                                            saveError.localizedDescription]];
        [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
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
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav pushViewController:confirm animated:NO];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark lifecycle

// make sure view controllers in the tabs can autorotate
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (toInterfaceOrientation == UIDeviceOrientationPortrait)
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([self.selectedViewController isKindOfClass:UINavigationController.class]) {
        UINavigationController *nc = (UINavigationController *)self.selectedViewController;
        return [nc.visibleViewController supportedInterfaceOrientations];
    } else {
        return [self.selectedViewController supportedInterfaceOrientations];
    }
}

- (void)handleUserSavedObservationNotification:(NSNotification *)notification
{
    [self setObservationsTabBadge];
}

- (void)setObservationsTabBadge
{
    NSInteger obsSyncCount = [Observation needingSyncCount] + [Observation deletedRecordCount];
    NSInteger photoSyncCount = [ObservationPhoto needingSyncCount];
    NSInteger theCount = obsSyncCount > 0 ? obsSyncCount : photoSyncCount;
    UITabBarItem *item = [self.tabBar.items objectAtIndex:4];       // Me tab
    if (theCount > 0) {
        item.badgeValue = [NSString stringWithFormat:@"%d", theCount];
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
    [makeFirstObsTooltip hideAnimated:NO];
}

#pragma mark - Fetch Iconic Taxa

- (void)fetchIconicTaxa {
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/taxa"
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        
                                                        loader.objectMapping = [Taxon mapping];
                                                        
                                                        loader.onDidLoadObjects = ^(NSArray *objects) {
                                                            
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
                                                        };
                                                    }];
}

@end
