//
//  INatUITabBarController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <DBCamera/DBCameraViewController.h>
#import <QBImagePickerController/QBImagePickerController.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "INatUITabBarController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "INatWebController.h"
#import "ObservationDetailViewController.h"
#import "ObsCameraView.h"
#import "ObsCameraViewController.h"
#import "ConfirmPhotoViewController.h"
#import "UIColor+INaturalist.h"

@interface INatUITabBarController () <UITabBarControllerDelegate, DBCameraViewControllerDelegate, QBImagePickerControllerDelegate>

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
    
    /*
    // guides gone entirely for now
    // make sure tabs fit OS version
    if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
        NSMutableArray * vcs = [NSMutableArray
                                arrayWithArray:[self viewControllers]];
        [vcs removeObjectAtIndex:3]; // remove guides tab
        [self setViewControllers:vcs];
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.tabBar.translucent = NO;
    }
     */
    
    self.delegate = self;
    
    // configure camera VC
    FAKIcon *camera = [FAKIonIcons ios7CameraIconWithSize:45];
    [camera addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    FAKIcon *cameraOutline = [FAKIonIcons ios7CameraOutlineIconWithSize:45];
    [cameraOutline addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    UIImage *img = [[UIImage imageWithStackedIcons:@[camera, cameraOutline] imageSize:CGSizeMake(34,45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    ((UIViewController *)[self.viewControllers objectAtIndex:1]).tabBarItem.image = img;
    ((UIViewController *)[self.viewControllers objectAtIndex:1]).tabBarItem.title = NSLocalizedString(@"New Observation", @"Title for New Observation Tab Bar Button");
    [((UIViewController *)[self.viewControllers objectAtIndex:1]).tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] }
                                                                                           forState:UIControlStateNormal];
    
    self.selectedIndex = 2;
    
    [super viewDidLoad];
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([tabBarController.viewControllers indexOfObject:viewController] == 1) {
        
        ObsCameraView *camera = [ObsCameraView initWithFrame:[[UIScreen mainScreen] bounds]];
        [camera buildInterface];
        
        ObsCameraViewController *cameraVC = [[ObsCameraViewController alloc] initWithDelegate:self cameraView:camera];
        [cameraVC setUseCameraSegue:NO];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:cameraVC];
        [nav setNavigationBarHidden:YES];
        
        [self presentViewController:nav animated:YES completion:nil];

        return NO;
    }
    return YES;
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
    
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav pushViewController:detail animated:YES];
}

#pragma mark - DBCamera delegate

- (void)camera:(UIViewController *)cameraViewController didFinishWithImage:(UIImage *)image withMetadata:(NSDictionary *)metadata {
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.image = image;
    confirm.metadata = metadata;
    confirm.shouldContinueUpdatingLocation = YES;
    [cameraViewController.navigationController pushViewController:confirm animated:YES];
}

- (void) dismissCamera:(id)cameraViewController{
    [self dismissViewControllerAnimated:YES completion:nil];
    [cameraViewController restoreFullScreenMode];
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
    UITabBarItem *item = [self.tabBar.items objectAtIndex:2];
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
@end
