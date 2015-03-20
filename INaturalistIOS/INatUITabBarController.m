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

#import "INatUITabBarController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "INatWebController.h"
#import "ObservationDetailViewController.h"
#import "ConfirmPhotoViewController.h"
#import "UIColor+INaturalist.h"
#import "ObsCameraOverlay.h"
#import "Taxon.h"

@interface INatUITabBarController () <UITabBarControllerDelegate, QBImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation INatUITabBarController

- (void)viewDidLoad
{
    [self setObservationsTabBadge];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleUserSavedObservationNotification:) 
                                                 name:INatUserSavedObservationNotification 
                                               object:nil];
    
    TTNavigator* navigator = [TTNavigator navigator];
    navigator.delegate = self;
    
    // tab bar delegate to intercept selection of the "observe" tab
    self.delegate = self;
    
    // configure camera VC
    FAKIcon *camera = [FAKIonIcons ios7CameraIconWithSize:45];
    [camera addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    FAKIcon *cameraOutline = [FAKIonIcons ios7CameraOutlineIconWithSize:45];
    [cameraOutline addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    UIImage *img = [[UIImage imageWithStackedIcons:@[camera, cameraOutline]
                                         imageSize:CGSizeMake(34,45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    ((UIViewController *)[self.viewControllers objectAtIndex:2]).tabBarItem.image = img;
    ((UIViewController *)[self.viewControllers objectAtIndex:2]).tabBarItem.title = NSLocalizedString(@"Observe", @"Title for New Observation Tab Bar Button");
    [((UIViewController *)[self.viewControllers objectAtIndex:2]).tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] }
                                                                                           forState:UIControlStateNormal];
    
    // Me tab
    self.selectedIndex = 4;
    
    // we'll use the iconic taxa during the new observation flow
    [self fetchIconicTaxa];
    
    [super viewDidLoad];
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    // intercept selection of the "observe" tab
    if ([tabBarController.viewControllers indexOfObject:viewController] == 2) {
        
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
                [self dismissViewControllerAnimated:YES completion:nil];
            } forControlEvents:UIControlEventTouchUpInside];
            
            // need to hide this based on available modes
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
            
            // need to hide this based on available modes
            [overlay.camera bk_addEventHandler:^(id sender) {
                if (picker.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
                    picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
                } else {
                    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                }
            } forControlEvents:UIControlEventTouchUpInside];
            
            [overlay.noPhoto bk_addEventHandler:^(id sender) {
                [self noPhoto];
            } forControlEvents:UIControlEventTouchUpInside];
            
            [overlay.shutter bk_addEventHandler:^(id sender) {
                [picker takePicture];
            } forControlEvents:UIControlEventTouchUpInside];
            
            [overlay.library bk_addEventHandler:^(id sender) {
                [self openLibrary];
            } forControlEvents:UIControlEventTouchUpInside];
            
            picker.cameraOverlayView = overlay;
            
            [self presentViewController:picker animated:YES completion:nil];
        } else {
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
    }
    return YES;
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.image = [info valueForKey:UIImagePickerControllerOriginalImage];
    confirm.metadata = [info valueForKey:UIImagePickerControllerMediaMetadata];
    confirm.shouldContinueUpdatingLocation = YES;
    [picker pushViewController:confirm animated:YES];
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
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ObservationDetailViewController *detail = [storyboard instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
    detail.observation = o;
    detail.shouldShowBigSaveButton = YES;
    
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav setNavigationBarHidden:NO];
    [nav pushViewController:detail animated:YES];
}

#pragma mark - QBImagePicker delegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets {
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.assets = assets;
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav pushViewController:confirm animated:YES];
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
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:theCount];
}

#pragma mark - TTNagigatorDelegate
// http://stackoverflow.com/questions/8771176/ttnavigator-not-pushing-onto-navigation-stack
- (BOOL)navigator: (TTBaseNavigator *)navigator shouldOpenURL:(NSURL *)url {
    UINavigationController *nc;
    if ([self.selectedViewController.presentedViewController isKindOfClass:UINavigationController.class]) {
        nc = (UINavigationController *)self.selectedViewController.presentedViewController;
    } else if ([self.selectedViewController isKindOfClass:UINavigationController.class]) {
        nc = (UINavigationController *)self.selectedViewController;
    }
    if (nc) {
        INatWebController *webController = [[INatWebController alloc] init];
        [webController openURL:url];
        [nc pushViewController:webController animated:YES];
    }
    return NO;
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
                                                                [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
                                                            }
                                                        };
                                                    }];
}

@end
