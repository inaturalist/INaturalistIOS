//
//  ConfirmObservationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <FontAwesomeKit/FAKFontAwesome.h>
#import <ActionSheetPicker-3.0/ActionSheetDatePicker.h>
#import <ActionSheetPicker-3.0/ActionSheetStringPicker.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <QBImagePickerController/QBImagePickerController.h>
#import <ImageIO/ImageIO.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <MHVideoPhotoGallery/MHTransitionDismissMHGallery.h>

#import "ObsEditV2ViewController.h"
#import "Observation.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "UIColor+INaturalist.h"
#import "DisclosureCell.h"
#import "TaxaSearchViewController.h"
#import "ProjectChooserViewController.h"
#import "ProjectObservation.h"
#import "TextViewCell.h"
#import "EditLocationViewController.h"
#import "SubtitleDisclosureCell.h"
#import "ObservationPhoto.h"
#import "ObsCameraOverlay.h"
#import "Observation+AddAssets.h"
#import "ConfirmPhotoViewController.h"
#import "FAKINaturalist.h"
#import "ProjectChooserViewController.h"
#import "Project.h"
#import "ObservationFieldValue.h"
#import "ProjectObservationField.h"
#import "ObservationField.h"
#import "ProjectObservationsViewController.h"
#import "ProjectUser.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "UploadManager.h"
#import "Analytics.h"
#import "PhotoScrollViewCell.h"
#import "ObsCenteredLabelCell.h"

typedef NS_ENUM(NSInteger, ConfirmObsSection) {
    ConfirmObsSectionPhotos = 0,
    ConfirmObsSectionIdentify,
    ConfirmObsSectionNotes,
    ConfirmObsSectionDelete,
};

@interface ObsEditV2ViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, EditLocationViewControllerDelegate, PhotoScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QBImagePickerControllerDelegate, TaxaSearchViewControllerDelegate, ProjectChooserViewControllerDelegate, CLLocationManagerDelegate, UIActionSheetDelegate> {
    
    CLLocationManager *_locationManager;
}
@property UIButton *saveButton;
@property (readonly) NSString *notesPlaceholder;
@property (readonly) CLLocationManager *locationManager;
@property UITapGestureRecognizer *tapDismissTextViewGesture;
@property CLGeocoder *geoCoder;
@end

@implementation ObsEditV2ViewController

#pragma mark - uiviewcontroller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tapDismissTextViewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(tapDismiss:)];
    self.tapDismissTextViewGesture.numberOfTapsRequired = 1;
    self.tapDismissTextViewGesture.numberOfTouchesRequired = 1;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelledNewObservation:)];

    self.tableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tv.translatesAutoresizingMaskIntoConstraints = NO;

        tv.dataSource = self;
        tv.delegate = self;
        
        [tv registerClass:[DisclosureCell class] forCellReuseIdentifier:@"disclosure"];
        [tv registerClass:[SubtitleDisclosureCell class] forCellReuseIdentifier:@"subtitleDisclosure"];
        [tv registerClass:[PhotoScrollViewCell class] forCellReuseIdentifier:@"photos"];
        [tv registerClass:[TextViewCell class] forCellReuseIdentifier:@"notes"];
        [tv registerClass:[ObsCenteredLabelCell class] forCellReuseIdentifier:@"singleButton"];
        
        tv.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, 0.01f)];
        tv.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, 0.01f)];

        tv;
    });
    [self.view addSubview:self.tableView];
    
    self.saveButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.backgroundColor = [UIColor inatTint];
        button.tintColor = [UIColor whiteColor];
        button.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:button.titleLabel.font.pointSize];

        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.loginController.isLoggedIn && [appDelegate.loginController.uploadManager isAutouploadEnabled]) {
            [button setTitle:NSLocalizedString(@"SHARE", @"Title for share new observation button")
                    forState:UIControlStateNormal];
        } else {
            [button setTitle:NSLocalizedString(@"SAVE", @"Title for save new observation button")
                    forState:UIControlStateNormal];
        }

        [button addTarget:self action:@selector(saved:) forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    // wait to add to self.view, since we don't always need it
    
    NSDictionary *views = @{
                            @"tv": self.tableView,
                            @"save": self.saveButton,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[tv]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    if (self.isMakingNewObservation) {
        // new obs confirm has a save button
        [self.view addSubview:self.saveButton];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-0-[save(==47)]-0-|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[save]-0-|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:views]];
        
        // new obs confirm has no Done nav bar button
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        // save existing obs has no save button
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-0-|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:views]];

        // save existing obs has a Done nav bar button
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(saved:)];
    }

    self.title = NSLocalizedString(@"Details", @"Title for confirm new observation details view");
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.tintColor = [UIColor inatTint];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.shouldContinueUpdatingLocation) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        
        [self startUpdatingLocation];
    }
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateObservationEdit
                          withProperties:@{ @"Mode": self.isMakingNewObservation ? @"New" : @"Edit" }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateObservationEdit];
}

- (void)dealloc {
    if (self.geoCoder) {
        [self.geoCoder cancelGeocode];
    }
    
    [self stopUpdatingLocation];
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // cancel, do nothing
    } else if (buttonIndex == 0) {
        // delete this observation
        [[Analytics sharedClient] event:kAnalyticsEventObservationDelete];
        
        // delete locally
        [self.observation deleteEntity];
        self.observation = nil;
        NSError *error;
        [[[RKObjectManager sharedManager] objectStore] save:&error];
        if (error) {
            // TODO: log it at least, also notify the user
        }
        
        // trigger the delete to happen on the server
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.loginController.uploadManager.shouldAutoupload) {
            [appDelegate.loginController.uploadManager autouploadPendingContent];
        }
        
        // pop to the root view controller
        UITabBarController *tab = (UITabBarController *)self.presentingViewController;
        UINavigationController *nav = (UINavigationController *)tab.selectedViewController;
        
        [tab dismissViewControllerAnimated:YES completion:^{
            [nav popToRootViewControllerAnimated:YES];
        }];
        
    }
}

#pragma mark - Autoupload Helper

- (void)triggerAutoUpload {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    if ([uploader shouldAutoupload]) {
        if (uploader.isNetworkAvailableForUpload) {
            [uploader autouploadPendingContent];
        } else {
            if (uploader.shouldNotifyAboutNetworkState) {
                [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Network Unavailable", nil)
                                           dismissAfter:4];
                [uploader notifiedAboutNetworkState];
            }
        }
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:self.notesPlaceholder]) {
        textView.textColor = [UIColor blackColor];
        textView.text = @"";
    }
    
    [self.view addGestureRecognizer:self.tapDismissTextViewGesture];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (![textView.text isEqualToString:self.observation.inatDescription]) {
        // text changed
        self.observation.inatDescription = textView.text;
        [[Analytics sharedClient] event:kAnalyticsEventObservationNotesChanged
                         withProperties:@{
                                          @"Via": [self analyticsVia]
                                          }];
    }
    
    if (textView.text.length == 0) {
        textView.textColor = [UIColor colorWithHexString:@"#AAAAAA"];
        textView.text = self.notesPlaceholder;
    }
    
    [self.view removeGestureRecognizer:self.tapDismissTextViewGesture];
}

#pragma mark - textview helper

- (NSString *)notesPlaceholder {
    return NSLocalizedString(@"Notes...", @"Placeholder for observation notes when making a new observation.");
}

- (void)tapDismiss:(UITapGestureRecognizer *)tapGesture {
    [self.tableView endEditing:YES];
}

#pragma mark - PhotoScrollViewDelegate

- (void)photoScrollView:(PhotoScrollViewCell *)psv setDefaultIndex:(NSInteger)idx {
    for (ObservationPhoto *photo in self.observation.observationPhotos) {
        if (photo.position.integerValue == idx) {
            photo.position = @(0);
        } else if (photo.position.integerValue < idx) {
            // needs to move down one
            photo.position = @(photo.position.integerValue + 1);
        }
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationNewDefaultPhoto
                     withProperties:@{ @"Via": [self analyticsVia] }];
    
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionPhotos] ]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)photoScrollView:(PhotoScrollViewCell *)psv deletedIndex:(NSInteger)idx {
    ObservationPhoto *photo = self.observation.sortedObservationPhotos[idx];
    NSPredicate *minusDeletedPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ![evaluatedObject isEqual:photo];
    }];
    NSSet *newObsPhotos = [self.observation.observationPhotos filteredSetUsingPredicate:minusDeletedPredicate];
    
    self.observation.observationPhotos = newObsPhotos;
    [photo deleteEntity];
    
    // update sortable
    for (int i = 0; i < self.observation.sortedObservationPhotos.count; i++) {
        ObservationPhoto *op = self.observation.sortedObservationPhotos[i];
        op.position = @(i);
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationDeletePhoto
                     withProperties:@{ @"Via": [self analyticsVia] }];
    
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionPhotos] ]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)photoScrollView:(PhotoScrollViewCell *)psv selectedIndex:(NSInteger)idx {
    // show the hires photo?
    ObservationPhoto *op = [self.observation.sortedObservationPhotos objectAtIndex:idx];
    if (!op) return;
    
    NSArray *galleryData = [self.observation.sortedObservationPhotos bk_map:^id(ObservationPhoto *op) {
        UIImage *img = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreLargeSize];
        return [MHGalleryItem itemWithImage:img];
    }];
    
    MHUICustomization *customization = [[MHUICustomization alloc] init];
    customization.showOverView = NO;
    customization.showMHShareViewInsteadOfActivityViewController = NO;
    customization.hideShare = YES;
    customization.useCustomBackButtonImageOnImageViewer = NO;
    
    MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarShown];
    gallery.galleryItems = galleryData;
    gallery.presentationIndex = idx;
    gallery.UICustomization = customization;
    gallery.presentingFromImageView = [psv imageViewForIndex:idx];
    
    __weak MHGalleryController *blockGallery = gallery;
    
    gallery.finishedCallback = ^(NSUInteger currentIndex,UIImage *image,MHTransitionDismissMHGallery *interactiveTransition,MHGalleryViewMode viewMode){
        __strong typeof(blockGallery)strongGallery = blockGallery;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongGallery dismissViewControllerAnimated:YES completion:nil];
        });
    };
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationViewHiresPhoto
                     withProperties:@{ @"Via": [self analyticsVia] }];
    
    [self presentMHGalleryController:gallery animated:YES completion:nil];

}

- (void)photoScrollViewAddPressed:(PhotoScrollViewCell *)psv {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self pushCamera];
    } else {
        [self pushLibrary];
    }
}

#pragma mark - PhotoScrollView helpers


- (void)pushLibrary {
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
    
    if (self.presentedViewController && [self.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)self.presentedViewController;
        [nav setNavigationBarHidden:NO animated:YES];
        [nav pushViewController:imagePickerController animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)pushCamera {
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
    
    overlay.noPhoto.hidden = YES;
    
    [overlay.shutter bk_addEventHandler:^(id sender) {
        [picker takePicture];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [overlay.library bk_addEventHandler:^(id sender) {
        [self pushLibrary];
    } forControlEvents:UIControlEventTouchUpInside];
    
    picker.cameraOverlayView = overlay;
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - QBImagePicker delegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets {
    // add to observation
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationAddPhoto
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"Source": @"Library",
                                      @"Count": @(assets.count)
                                      }];
    
    __weak __typeof__(self) weakSelf = self;
    [self.observation addAssets:assets
                      afterEach:^(ObservationPhoto *op) {
                          __typeof__(self) strongSelf = weakSelf;
                          if (strongSelf) {
                              [strongSelf.tableView reloadData];
                          }
                      }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // add metadata with geo
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:[self.observation.visibleLatitude doubleValue]
                                                 longitude:[self.observation.visibleLongitude doubleValue]];
    NSMutableDictionary *meta = [((NSDictionary *)[info objectForKey:UIImagePickerControllerMediaMetadata]) mutableCopy];
    [meta setValue:[self getGPSDictionaryForLocation:loc]
            forKey:((NSString * )kCGImagePropertyGPSDictionary)];
    confirm.metadata = meta;
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationAddPhoto
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"Source": @"Camera",
                                      @"Count": @(1)
                                      }];

    // set the follow up action
    confirm.confirmFollowUpAction = ^(NSArray *assets) {
        
        __weak __typeof__(self) weakSelf = self;
        [self.observation addAssets:assets afterEach:^(ObservationPhoto *op) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf.tableView reloadData];
            }
        }];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    [picker pushViewController:confirm animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // workaround for a crash in Apple's didHideZoomSlider
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

// http://stackoverflow.com/a/5314634/720268
- (NSDictionary *)getGPSDictionaryForLocation:(CLLocation *)location {
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];
    
    // GPS tag version
    [gps setObject:@"2.2.0.0" forKey:(NSString *)kCGImagePropertyGPSVersion];
    
    // Time and date must be provided as strings, not as an NSDate object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
    [formatter setDateFormat:@"yyyy:MM:dd"];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
    
    // Latitude
    CGFloat latitude = location.coordinate.latitude;
    if (latitude < 0) {
        latitude = -latitude;
        [gps setObject:@"S" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    } else {
        [gps setObject:@"N" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:latitude] forKey:(NSString *)kCGImagePropertyGPSLatitude];
    
    // Longitude
    CGFloat longitude = location.coordinate.longitude;
    if (longitude < 0) {
        longitude = -longitude;
        [gps setObject:@"W" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    } else {
        [gps setObject:@"E" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:longitude] forKey:(NSString *)kCGImagePropertyGPSLongitude];
    
    // Altitude
    CGFloat altitude = location.altitude;
    if (!isnan(altitude)){
        if (altitude < 0) {
            altitude = -altitude;
            [gps setObject:@"1" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        } else {
            [gps setObject:@"0" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        }
        [gps setObject:[NSNumber numberWithFloat:altitude] forKey:(NSString *)kCGImagePropertyGPSAltitude];
    }
    
    // Speed, must be converted from m/s to km/h
    if (location.speed >= 0){
        [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
        [gps setObject:[NSNumber numberWithFloat:location.speed*3.6] forKey:(NSString *)kCGImagePropertyGPSSpeed];
    }
    
    // Heading
    if (location.course >= 0){
        [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
        [gps setObject:[NSNumber numberWithFloat:location.course] forKey:(NSString *)kCGImagePropertyGPSTrack];
    }
    
    return gps;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startUpdatingLocation];
            break;
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location Services Denied", nil)
                                        message:NSLocalizedString(@"Cannot use your location", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
            break;
        case kCLAuthorizationStatusNotDetermined:
        default:
            // do nothing
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {

    if (newLocation.timestamp.timeIntervalSinceNow < -60) return;
    
    // self.observation can be momentarily nil when it's being deleted
    if (!self.observation) return;
    
    @try {
        self.observation.latitude = @(newLocation.coordinate.latitude);
        self.observation.longitude = @(newLocation.coordinate.longitude);
        self.observation.privateLatitude = nil;
        self.observation.privateLongitude = nil;
        self.observation.positionalAccuracy = @(newLocation.horizontalAccuracy);
        self.observation.positioningMethod = @"gps";
        
        self.observation.localUpdatedAt = [NSDate date];
        
        NSIndexPath *ip = [NSIndexPath indexPathForItem:2 inSection:ConfirmObsSectionNotes];
        [self.tableView reloadRowsAtIndexPaths:@[ ip ] withRowAnimation:UITableViewRowAnimationFade];
        
        if (newLocation.horizontalAccuracy < 10) {
            [self stopUpdatingLocation];
        }
        
        if (self.observation.placeGuess.length == 0 || [newLocation distanceFromLocation:oldLocation] > 100) {
            [self reverseGeocodeCoordinatesForObservation:self.observation];
        }
    } @catch (NSException *exception) {
        if ([exception.name isEqualToString:NSObjectInaccessibleException]) {
            // if self.observation has been deleted or is otherwise inaccessible, do nothing
            return;
        } else {
            // unanticpated exception
            @throw(exception);
        }
    }
}

#pragma mark - Location Manager helpers

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

- (void)startUpdatingLocation {
    [self.locationManager startUpdatingLocation];
}


#pragma mark - geocoding helper

- (void)reverseGeocodeCoordinatesForObservation:(Observation *)obs {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:obs.latitude.floatValue
                                                 longitude:obs.longitude.floatValue];
    
    if (!self.geoCoder)
        self.geoCoder = [[CLGeocoder alloc] init];
    
    [self.geoCoder cancelGeocode];       // cancel anything in flight
    
    [self.geoCoder reverseGeocodeLocation:loc
                        completionHandler:^(NSArray *placemarks, NSError *error) {
                            CLPlacemark *placemark = [placemarks firstObject];
                            if (placemark) {
                                @try {
                                    NSString *name = placemark.name ?: @"";
                                    NSString *locality = placemark.locality ?: @"";
                                    NSString *administrativeArea = placemark.administrativeArea ?: @"";
                                    NSString *ISOcountryCode = placemark.ISOcountryCode ?: @"";
                                    obs.placeGuess = [ @[ name,
                                                          locality,
                                                          administrativeArea,
                                                          ISOcountryCode ] componentsJoinedByString:@", "];
                                    NSIndexPath *locRowIp = [NSIndexPath indexPathForItem:2 inSection:ConfirmObsSectionNotes];
                                    [self.tableView reloadRowsAtIndexPaths:@[ locRowIp ]
                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                                } @catch (NSException *exception) {
                                    if ([exception.name isEqualToString:NSObjectInaccessibleException])
                                        return;
                                    else
                                        @throw exception;
                                }
                            }
                        }];
}

#pragma mark - UISwitch targets

- (void)idPleaseChanged:(UISwitch *)switcher {
    [[Analytics sharedClient] event:kAnalyticsEventObservationIDPleaseChanged
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"New Value": switcher.isOn ? @"Yes": @"No"
                                      }];
    
    self.observation.idPlease = [NSNumber numberWithBool:switcher.isOn];
}

#pragma mark - UIButton targets

- (void)taxonDeleted:(UIButton *)button {
    [[Analytics sharedClient] event:kAnalyticsEventObservationTaxonChanged
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"New Value": @"No Taxon"
                                      }];

    self.observation.speciesGuess = nil;
    self.observation.taxon = nil;
    self.observation.taxonID = nil;
    self.observation.iconicTaxonID = nil;
    self.observation.iconicTaxonName = nil;
    
    NSIndexPath *speciesIndexPath = [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionIdentify];
    [self.tableView reloadRowsAtIndexPaths:@[ speciesIndexPath ]
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (void)cancelledNewObservation:(UIBarButtonItem *)item {
    if (self.isMakingNewObservation) {
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationCancel];
        
        [self.observation deleteEntity];
        self.observation = nil;
        NSError *error;
        [[[RKObjectManager sharedManager] objectStore] save:&error];
        if (error) {
            // TODO: log it at least, also notify the user
        }
    } else {
        [self.observation.managedObjectContext rollback];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)saved:(UIButton *)button {
    [self.view endEditing:YES];
    
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationSaveObservation
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"Projects": @(self.observation.projectObservations.count),
                                      @"Photos": @(self.observation.observationPhotos.count),
                                      @"OFVs": @(self.observation.observationFieldValues.count)
                                      }];
    
    self.observation.localUpdatedAt = [NSDate date];
    
    NSError *error;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        // TODO: log it at least, also notify the user
    }
    
    [self triggerAutoUpload];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Project Chooser

- (void)projectChooserViewController:(ProjectChooserViewController *)controller choseProjects:(NSArray *)projects {
    [self.navigationController popToViewController:self animated:YES];
    
    NSMutableArray *newProjects = [NSMutableArray arrayWithArray:projects];
    NSMutableSet *deletedProjects = [[NSMutableSet alloc] init];
    for (ProjectObservation *po in self.observation.projectObservations) {
        if ([projects containsObject:po.project]) {
            [newProjects removeObject:po.project];
        } else {
            [po deleteEntity];
            [deletedProjects addObject:po];
        }
        self.observation.localUpdatedAt = [NSDate date];
    }
    [self.observation removeProjectObservations:deletedProjects];
    
    if (newProjects.count > 0 || deletedProjects.count > 0) {
        [[Analytics sharedClient] event:kAnalyticsEventObservationProjectsChanged
                         withProperties:@{
                                          @"Via": [self analyticsVia],
                                          }];
    }
    
    for (Project *project in newProjects) {
        ProjectObservation *po = [ProjectObservation object];
        po.observation = self.observation;
        po.project = project;
        
        for (ProjectObservationField *pof in project.sortedProjectObservationFields) {
            ObservationFieldValue *ofv = [ObservationFieldValue object];
            ofv.observation = self.observation;
            ofv.observationField = pof.observationField;
        }

        self.observation.localUpdatedAt = [NSDate date];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Taxa Search

- (void)taxaSearchViewControllerChoseTaxon:(Taxon *)taxon {
    self.observation.taxon = taxon;
    self.observation.taxonID = taxon.recordID;
    self.observation.iconicTaxonName = taxon.iconicTaxonName;
    self.observation.iconicTaxonID = taxon.iconicTaxonID;
    self.observation.speciesGuess = taxon.defaultName;
    
    self.observation.localUpdatedAt = [NSDate date];

    NSString *newTaxonName = taxon.defaultName ?: taxon.name;
    if (!newTaxonName) { newTaxonName = @"Something"; }
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationTaxonChanged
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"New Value": newTaxonName,
                                      @"Is Taxon": @"Yes",
                                      }];

    [self.navigationController popToViewController:self animated:YES];
}

- (void)taxaSearchViewControllerChoseSpeciesGuess:(NSString *)speciesGuess {
    // clear out any previously set taxon information
    self.observation.taxon = nil;
    self.observation.taxonID = nil;
    self.observation.iconicTaxonName = nil;
    self.observation.iconicTaxonID = nil;

    self.observation.localUpdatedAt = [NSDate date];

    self.observation.speciesGuess = speciesGuess;
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationTaxonChanged
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"New Value": speciesGuess,
                                      @"Is Taxon": @"No",
                                      }];
    
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - EditLocationDelegate

- (void)editLocationViewControllerDidSave:(EditLocationViewController *)controller location:(INatLocation *)location {
    
    if (location.latitude.integerValue == 0 && location.longitude.integerValue == 0) {
        // nothing happens on null island
        return;
    }
    
    self.observation.latitude = location.latitude;
    self.observation.longitude = location.longitude;
    self.observation.positionalAccuracy = location.accuracy;
    self.observation.positioningMethod = location.positioningMethod;
    self.observation.placeGuess = nil;
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationLocationChanged
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      }];

    [self.navigationController popToViewController:self animated:YES];

    [self reverseGeocodeCoordinatesForObservation:self.observation];
}

- (void)editLocationViewControllerDidCancel:(EditLocationViewController *)controller {
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - table view delegate / datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // if making a new obs, no delete section
    return self.isMakingNewObservation ? 3 : 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ConfirmObsSectionPhotos:
            return 1;
            break;
        case ConfirmObsSectionIdentify:
            return 2;
            break;
        case ConfirmObsSectionNotes:
            return 6;
            break;
        case ConfirmObsSectionDelete:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ConfirmObsSectionPhotos:
            return 108;
            break;
        case ConfirmObsSectionIdentify:
            if (indexPath.item == 0) {
                return [DisclosureCell heightForRowWithTitle:self.observation.taxon.defaultName ?: NSLocalizedString(@"Something...", nil)
                                                 inTableView:tableView];
            } else if (indexPath.item == 1) {
                return [DisclosureCell heightForRowWithTitle:[self needsIDTitle]
                                                 inTableView:tableView];
            }
        case ConfirmObsSectionNotes:
            if (indexPath.item == 0) {
                // notes
                return 66;
            } else if (indexPath.item == 1) {
                // datetime
                return 44;
            } else if (indexPath.item == 2) {
                // location
                return (self.observation.latitude && self.observation.longitude) ? 66 : 44;
            } else if (indexPath.item == 3) {
                return [DisclosureCell heightForRowWithTitle:[self geoPrivacyTitle]
                                                 inTableView:tableView];
            } else if (indexPath.item == 4) {
                return [DisclosureCell heightForRowWithTitle:[self captiveTitle]
                                                 inTableView:tableView];
            } else if (indexPath.item == 5) {
                return [DisclosureCell heightForRowWithTitle:[self projectsTitle]
                                                 inTableView:tableView];
            }
    }
    
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ConfirmObsSectionPhotos:
            return 0;
            break;
        case ConfirmObsSectionIdentify:
        case ConfirmObsSectionDelete:
            return 34;
            break;
        case ConfirmObsSectionNotes:
            return 2;
            break;
        default:
            return 0;
            break;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.separatorInset = UIEdgeInsetsMake(0, 59, 0, 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case ConfirmObsSectionPhotos:
            return [self photoCellInTableView:tableView];
            break;
        case ConfirmObsSectionIdentify:
            if (indexPath.item == 0) {
                return [self speciesCellInTableView:tableView];
            } else {
                return [self helpIdCellInTableView:tableView];
            }
            break;
        case ConfirmObsSectionNotes:
            if (indexPath.item == 0) {
                return [self notesCellInTableView:tableView];
            } else if (indexPath.item == 1) {
                return [self dateTimeCellInTableView:tableView];
            } else if (indexPath.item == 2) {
                return [self locationCellInTableView:tableView];
            } else if (indexPath.item == 3) {
                return [self geoPrivacyCellInTableView:tableView];
            } else if (indexPath.item == 4) {
                return [self captiveCellInTableView:tableView];
            } else if (indexPath.item == 5) {
                return [self projectsCellInTableView:tableView];
            } else {
                return [self illegalCellForIndexPath:indexPath];
            }
            break;
        case ConfirmObsSectionDelete:
            if (indexPath.item == 0) {
                return [self deleteCellInTableView:tableView];
            }
        default:
            return [self illegalCellForIndexPath:indexPath];
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case ConfirmObsSectionPhotos:
            // do nothing
            break;
        case ConfirmObsSectionIdentify:
            if (indexPath.item == 0) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                
                TaxaSearchViewController *search = [storyboard instantiateViewControllerWithIdentifier:@"TaxaSearchViewController"];
                search.hidesDoneButton = YES;
                search.delegate = self;
                search.query = self.observation.speciesGuess;
                search.allowsFreeTextSelection = YES;
                [self.navigationController pushViewController:search animated:YES];
            } else {
                // do nothing
            }
            break;
        case ConfirmObsSectionNotes:
            if (indexPath.item == 0) {
                // do nothing
            } else if (indexPath.item == 1) {
                // show date/time action sheet picker
                __weak typeof(self) weakSelf = self;
                [[[ActionSheetDatePicker alloc] initWithTitle:NSLocalizedString(@"Select Date", @"title for date selector")
                                               datePickerMode:UIDatePickerModeDateAndTime
                                                 selectedDate:self.observation.localObservedOn
                                                    doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                                        
                                                        NSDate *date = (NSDate *)selectedDate;
                                                        
                                                        if ([date timeIntervalSinceDate:self.observation.localObservedOn] == 0) {
                                                            // nothing changed
                                                            return;
                                                        }
                                                        
                                                        if ([date timeIntervalSinceNow] > 0) {
                                                            NSString *alertTitle = NSLocalizedString(@"Invalid Date",
                                                                                                     @"Invalid date alert title");
                                                            NSString *alertMsg = NSLocalizedString(@"Cannot choose a date in the future.",
                                                                                                   @"Alert message for invalid date");
                                                            [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                                        message:alertMsg
                                                                                       delegate:nil
                                                                              cancelButtonTitle:@"OK"
                                                                              otherButtonTitles:nil] show];
                                                            return;
                                                        }
                                                        
                                                        [[Analytics sharedClient] event:kAnalyticsEventObservationDateChanged\
                                                                         withProperties:@{
                                                                                          @"Via": [self analyticsVia]
                                                                                          }];

                                                        
                                                        __strong typeof(weakSelf) strongSelf = self;
                                                        strongSelf.observation.localObservedOn = date;
                                                        strongSelf.observation.observedOnString = [Observation.jsDateFormatter stringFromDate:date];
                                                        
                                                        [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                    withRowAnimation:UITableViewRowAnimationFade];
                                                        
                                                    } cancelBlock:nil
                                                       origin:cell] showActionSheetPicker];
            } else if (indexPath.item == 2) {
                // show location chooser
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                EditLocationViewController *map = [storyboard instantiateViewControllerWithIdentifier:@"EditLocationViewController"];
                map.delegate = self;
                
                if (self.observation.visibleLatitude) {
                    INatLocation *loc = [[INatLocation alloc] initWithLatitude:self.observation.visibleLatitude
                                                                     longitude:self.observation.visibleLongitude
                                                                      accuracy:self.observation.positionalAccuracy];
                    loc.positioningMethod = self.observation.positioningMethod;
                    [map setCurrentLocation:loc];
                } else {
                    [map setCurrentLocation:nil];
                }

                [self.navigationController pushViewController:map animated:YES];
            } else if (indexPath.item == 3) {
                // geoprivacy
                
                // really want swift enums here
                NSArray *geoprivacyOptions = @[@"open", @"obscured", @"private"];
                NSArray *presentableGeoPrivacyOptions = @[
                                                          NSLocalizedString(@"Open", @"open geoprivacy"),
                                                          NSLocalizedString(@"Obscured", @"obscured geoprivacy"),
                                                          NSLocalizedString(@"Private", @"private geoprivacy"),
                                                          ];

                NSInteger initialSelection = [geoprivacyOptions indexOfObject:self.observation.geoprivacy];
                if (initialSelection == NSNotFound) {
                    initialSelection = 0;
                }
                
                __weak typeof(self) weakSelf = self;
                [[[ActionSheetStringPicker alloc] initWithTitle:NSLocalizedString(@"Select Privacy", @"title for geoprivacy selector")
                                                           rows:presentableGeoPrivacyOptions
                                               initialSelection:initialSelection
                                                      doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                          
                                                          if (initialSelection == selectedIndex) { return; }
                                                          
                                                          __strong typeof(weakSelf) strongSelf = weakSelf;
                                                          NSString *newValue = geoprivacyOptions[selectedIndex];
                                                          
                                                          strongSelf.observation.geoprivacy = newValue;

                                                          [[Analytics sharedClient] event:kAnalyticsEventObservationGeoprivacyChanged
                                                                           withProperties:@{ @"Via": [self analyticsVia],
                                                                                             @"New Value": newValue}];
                                                          
                                                          [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                      withRowAnimation:UITableViewRowAnimationFade];

                                                      } cancelBlock:nil
                                                         origin:cell] showActionSheetPicker];
            } else if (indexPath.item == 4) {
                // captive/cultivated
                
                NSArray *captiveOptions = @[@"No", @"Yes"];
                NSInteger selectedIndex = self.observation.captive.integerValue;
                
                __weak typeof(self) weakSelf = self;
                [[[ActionSheetStringPicker alloc] initWithTitle:NSLocalizedString(@"Captive?", @"title for captive selector")
                                                           rows:captiveOptions
                                               initialSelection:selectedIndex
                                                      doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                          
                                                          [[Analytics sharedClient] event:kAnalyticsEventObservationCaptiveChanged
                                                                           withProperties:@{
                                                                                            @"Via": [self analyticsVia],
                                                                                            @"New Value": selectedIndex == 0 ? @"No": @"Yes",
                                                                                            }];
                                                          
                                                          __strong typeof(weakSelf) strongSelf = weakSelf;
                                                          
                                                          strongSelf.observation.captive = @(selectedIndex);
                                                          
                                                          [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                      withRowAnimation:UITableViewRowAnimationFade];
                                                          
                                                      } cancelBlock:nil
                                                         origin:cell] showActionSheetPicker];
            } else if (indexPath.item == 5) {
                INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
                if (appDelegate.loginController.isLoggedIn) {
                    ProjectObservationsViewController *projectsVC = [[ProjectObservationsViewController alloc] initWithNibName:nil bundle:nil];
                    projectsVC.observation = self.observation;
                    
                    NSMutableArray *projects = [NSMutableArray array];
                    [[ProjectUser all] enumerateObjectsUsingBlock:^(ProjectUser *pu, NSUInteger idx, BOOL *stop) {
                        [projects addObject:pu.project];
                    }];
                    
                    projectsVC.joinedProjects = [projects sortedArrayUsingComparator:^NSComparisonResult(Project *p1, Project *p2) {
                        return [p1.title compare:p2.title];
                    }];

                    [self.navigationController pushViewController:projectsVC animated:YES];
                } else {
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You must be logged in!", nil)
                                                message:NSLocalizedString(@"You must be logged in to access projects.", nil)
                                               delegate:nil
                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                      otherButtonTitles:nil] show];
                }

            
            } else {
                // do nothing
            }
            break;
        case ConfirmObsSectionDelete:
            // show alertview
            [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure? This is permanent.", nil)
                                         delegate:self
                                cancelButtonTitle:NSLocalizedString(@"Never mind", nil)
                           destructiveButtonTitle:NSLocalizedString(@"Yes, delete this observation", nil)
                                otherButtonTitles:nil] showInView:self.view];
            
            break;
        default:
            // do nothing
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ConfirmObsSectionIdentify:
            return NSLocalizedString(@"What did you see?", @"title for identification section of new obs confirm screen.");
            break;
        case ConfirmObsSectionPhotos:
        case ConfirmObsSectionNotes:
        case ConfirmObsSectionDelete:
            return nil;
            break;
        default:
            return nil;
            break;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.tableView]) {
        [self.tableView endEditing:YES];
    }
}

#pragma mark - table view cell helpers

- (UITableViewCell *)photoCellInTableView:(UITableView *)tableView {
    PhotoScrollViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"photos"];
    
    cell.photos = self.observation.sortedObservationPhotos;
    cell.delegate = self;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (UITableViewCell *)speciesCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    UIButton *deleteButton = ({
        FAKIcon *deleteIcon = [FAKIonIcons iosCloseIconWithSize:29];
        [deleteIcon addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [button setAttributedTitle:deleteIcon.attributedString forState:UIControlStateNormal];
        [button addTarget:self action:@selector(taxonDeleted:) forControlEvents:UIControlEventTouchUpInside];
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        
        button;
    });


    if (self.observation.taxon) {
        
        Taxon *taxon = self.observation.taxon;
        cell.titleLabel.text = taxon.defaultName;
        
        cell.cellImageView.layer.borderWidth = 0.5f;
        cell.cellImageView.layer.borderColor = [UIColor colorWithHexString:@"#777777"].CGColor;
        cell.cellImageView.layer.cornerRadius = 3.0f;

        if ([taxon.isIconic boolValue]) {
            cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        } else if (taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = taxon.taxonPhotos.firstObject;
            [cell.cellImageView sd_setImageWithURL:[NSURL URLWithString:tp.thumbURL]];
        } else {
            cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        }
        
        cell.accessoryView = deleteButton;
        
    } else {
        FAKIcon *question = [FAKINaturalist speciesUnknownIconWithSize:44];
        [question addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
        cell.cellImageView.image = [question imageWithSize:CGSizeMake(44, 44)];
        
        if (self.observation.speciesGuess) {
            cell.titleLabel.text = self.observation.speciesGuess;
            cell.accessoryView = deleteButton;
        } else {
            cell.titleLabel.text = NSLocalizedString(@"Something...", nil);
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (UITableViewCell *)helpIdCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = [self needsIDTitle];
    FAKIcon *bouy = [FAKINaturalist icnIdHelpIconWithSize:44];
    [bouy addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
    cell.cellImageView.image = [bouy imageWithSize:CGSizeMake(44, 44)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switcher addTarget:self action:@selector(idPleaseChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switcher;
    
    return cell;
}

- (UITableViewCell *)notesCellInTableView:(UITableView *)tableView {
    TextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notes"];
    
    if (self.observation.inatDescription && self.observation.inatDescription.length > 0) {
        cell.textView.text = self.observation.inatDescription;
        cell.textView.textColor = [UIColor blackColor];
    } else {
        cell.textView.text = self.notesPlaceholder;
        cell.textView.textColor = [UIColor grayColor];
    }
    cell.textView.delegate = self;

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (UITableViewCell *)dateTimeCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = [self.observation observedOnPrettyString];
    FAKIcon *calendar = [FAKINaturalist iosCalendarOutlineIconWithSize:44];
    [calendar addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
    cell.cellImageView.image = [calendar imageWithSize:CGSizeMake(44, 44)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)locationCellInTableView:(UITableView *)tableView {
    
    DisclosureCell *cell;

    if (self.observation.latitude && self.observation.longitude) {
        
        SubtitleDisclosureCell *subtitleCell = [tableView dequeueReusableCellWithIdentifier:@"subtitleDisclosure"];
        cell = subtitleCell;
        
        NSString *positionalAccuracy = nil;
        if (self.observation.positionalAccuracy) {
            positionalAccuracy = [NSString stringWithFormat:@"%ld m", (long)self.observation.positionalAccuracy.integerValue];
        } else {
            positionalAccuracy = NSLocalizedString(@"???", @"positional accuracy when we don't know");
        }
        NSString *subtitleString = [NSString stringWithFormat:@"Lat: %.3f  Lon: %.3f  Acc: %@",
                                    self.observation.latitude.floatValue,
                                    self.observation.longitude.floatValue,
                                    positionalAccuracy];
        subtitleCell.subtitleLabel.text = subtitleString;
        
        if (self.observation.placeGuess && self.observation.placeGuess.length > 0) {
            subtitleCell.titleLabel.text = self.observation.placeGuess;
        } else {
            subtitleCell.titleLabel.text = NSLocalizedString(@"Location not geocoded", @"place guess when we have lat/lng but it's not geocoded");
            
            // try again
            [self reverseGeocodeCoordinatesForObservation:self.observation];
        }
        
        
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
        cell.titleLabel.text = NSLocalizedString(@"No location", @"place guess when we have no location information");
    }
    
    FAKIcon *pin = [FAKIonIcons iosLocationOutlineIconWithSize:44];
    [pin addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
    cell.cellImageView.image = [pin imageWithSize:CGSizeMake(44, 44)];
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)geoPrivacyCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = [self geoPrivacyTitle];
    cell.secondaryLabel.text = self.observation.presentableGeoprivacy;
    
    FAKIcon *globe = [FAKIonIcons iosWorldOutlineIconWithSize:44];
    [globe addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
    cell.cellImageView.image = [globe imageWithSize:CGSizeMake(44, 44)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)captiveCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = [self captiveTitle];
    cell.secondaryLabel.text = self.observation.captive.boolValue ? NSLocalizedString(@"Yes", nil) : NSLocalizedString(@"No", nil);
    FAKIcon *captive = [FAKINaturalist captiveIconWithSize:44];
    [captive addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
    cell.cellImageView.image = [captive imageWithSize:CGSizeMake(44, 44)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (UITableViewCell *)projectsCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = [self projectsTitle];
    FAKIcon *project = [FAKIonIcons iosBriefcaseOutlineIconWithSize:44];
    [project addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
    cell.cellImageView.image = [project imageWithSize:CGSizeMake(44, 44)];
    
    if (self.observation.projectObservations.count > 0) {
        cell.secondaryLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.observation.projectObservations.count];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)deleteCellInTableView:(UITableView *)tableView {
    ObsCenteredLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"singleButton"];
    
    cell.centeredLabel.textColor = [UIColor redColor];
    cell.centeredLabel.text = NSLocalizedString(@"Delete Observation", @"text of delete obs button");
    cell.centeredLabel.font = [UIFont systemFontOfSize:17.0f];
    
    return cell;
}

- (UITableViewCell *)illegalCellForIndexPath:(NSIndexPath *)ip {
    NSLog(@"indexpath is %@", ip);
    NSAssert(NO, @"illegal cell for confirm screen");
}

#pragma mark - UITableViewCell title helpers

- (NSString *)needsIDTitle {
    return NSLocalizedString(@"Help Me ID This Species", nil);
}

- (NSString *)geoPrivacyTitle {
    return NSLocalizedString(@"Geo Privacy", @"Geoprivacy button title");
}

- (NSString *)captiveTitle {
    return NSLocalizedString(@"Captive / Cultivated", @"Captive / cultivated button title.");
}

- (NSString *)projectsTitle {
    return NSLocalizedString(@"Projects", @"choose projects button title.");
}

#pragma mark - analytics helper

- (NSString *)analyticsVia {
    return self.isMakingNewObservation ? @"New" : @"Edit";
}

@end
