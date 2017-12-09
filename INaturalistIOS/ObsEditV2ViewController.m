//
//  ConfirmObservationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <FontAwesomeKit/FAKFontAwesome.h>
#import <ActionSheetPicker-3.0/ActionSheetDatePicker.h>
#import <ActionSheetPicker-3.0/ActionSheetStringPicker.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <QBImagePickerController/QBImagePickerController.h>
#import <ImageIO/ImageIO.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <MHVideoPhotoGallery/MHTransitionDismissMHGallery.h>
#import <RestKit/RestKit.h>

#import "ObsEditV2ViewController.h"
#import "Observation.h"
#import "Taxon.h"
#import "ExploreTaxonRealm.h"
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
#import "ObsDetailTaxonCell.h"
#import "ExploreUpdateRealm.h"
#import "INatReachability.h"

typedef NS_ENUM(NSInteger, ConfirmObsSection) {
    ConfirmObsSectionPhotos = 0,
    ConfirmObsSectionIdentify,
    ConfirmObsSectionNotes,
    ConfirmObsSectionDelete,
};

@interface QBImagePickerController ()
@property (nonatomic, strong) UINavigationController *albumsNavigationController;
@end

@interface ObsEditV2ViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, EditLocationViewControllerDelegate, PhotoScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QBImagePickerControllerDelegate, TaxaSearchViewControllerDelegate, ProjectChooserViewControllerDelegate, CLLocationManagerDelegate> {
    
    CLLocationManager *_locationManager;
}
@property UIButton *saveButton;
@property (readonly) NSString *notesPlaceholder;
@property (readonly) CLLocationManager *locationManager;
@property UITapGestureRecognizer *tapDismissTextViewGesture;
@property CLGeocoder *geoCoder;
@property QBImagePickerController *imagePicker;
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
        
        // we share this cell design with the obs detail screen (and eventually others)
        // so we load it from a nib rather than from the storyboard, which locks the
        // cell into a single view controller scene
        [tv registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil] forCellReuseIdentifier:@"taxonFromNib"];
        
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
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stopUpdatingLocation];
}

- (void)dealloc {
    if (self.geoCoder) {
        [self.geoCoder cancelGeocode];
    }
    
    [self stopUpdatingLocation];
}

- (void)deleteThisObservation {
    // delete this observation
    [[Analytics sharedClient] event:kAnalyticsEventObservationDelete];
    
    // delete all related updates
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    NSString *predString = [NSString stringWithFormat:@"resourceId == %ld",
                            (unsigned long)[[self.observation recordID] integerValue]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predString];
    RLMResults *results = [ExploreUpdateRealm objectsWithPredicate:predicate];
    [realm deleteObjects:results];
    [realm commitWriteTransaction];
    
    // delete locally
    [self.observation deleteEntity];
    self.observation = nil;
    NSError *error;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        // TODO: log it at least, also notify the user
    }
    
    // trigger the delete to happen on the server
    [self triggerAutoUpload];
    
    // pop to the root view controller
    // dispatch/enqueue this to allow the popover controller on ipad
    // (which presents the action sheet) to dismiss first
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarController *tab = (UITabBarController *)self.presentingViewController;
        UINavigationController *nav = (UINavigationController *)tab.selectedViewController;
        
        [tab dismissViewControllerAnimated:YES completion:^{
            [nav popToRootViewControllerAnimated:YES];
        }];
    });
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
        self.observation.localUpdatedAt = [NSDate date];
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
    ObservationPhoto *newDefault = self.observation.sortedObservationPhotos[idx];
    newDefault.position = @(0);
    newDefault.localUpdatedAt = [NSDate date];
    
    for (ObservationPhoto *photo in self.observation.observationPhotos) {
        if ([photo isEqual:newDefault]) {
            continue;
        }
        if (photo.position.integerValue < idx) {
            // needs to move down one
            photo.position = @(photo.position.integerValue + 1);
            photo.localUpdatedAt = [NSDate date];
        }
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationNewDefaultPhoto
                     withProperties:@{ @"Via": [self analyticsVia] }];
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionPhotos] ]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
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
        op.updatedAt = [NSDate date];
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationDeletePhoto
                     withProperties:@{ @"Via": [self analyticsVia] }];
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionPhotos] ]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)photoScrollView:(PhotoScrollViewCell *)psv selectedIndex:(NSInteger)idx {
    ObservationPhoto *op = [self.observation.sortedObservationPhotos objectAtIndex:idx];
    if (!op) return;
    
    NSArray *galleryData = [self.observation.sortedObservationPhotos bk_map:^id(ObservationPhoto *op) {
        UIImage *img = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSmallSize];
        if (img) {
            return [MHGalleryItem itemWithImage:img];
        } else {
            return [MHGalleryItem itemWithURL:op.largePhotoUrl.absoluteString
                                  galleryType:MHGalleryTypeImage];
        }
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
    
    gallery.finishedCallback = ^(NSInteger currentIndex, UIImage *image, MHTransitionDismissMHGallery *interactiveTransition, MHGalleryViewMode viewMode) {
        
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
    // qbimagepicker for library multi-select
    self.imagePicker = [[QBImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.allowsMultipleSelection = YES;
    self.imagePicker.maximumNumberOfSelection = 4;     // arbitrary
    self.imagePicker.mediaType = QBImagePickerMediaTypeImage;
    self.imagePicker.assetCollectionSubtypes = [ImageStore assetCollectionSubtypes];
    
    if (self.presentedViewController) {
        UINavigationController *nav = (UINavigationController *)self.presentedViewController;
        [nav pushViewController:self.imagePicker.albumsNavigationController.topViewController animated:YES];
        [nav setNavigationBarHidden:NO animated:YES];
    } else {
        [self presentViewController:self.imagePicker animated:YES completion:nil];
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

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.assets = assets;
    __weak typeof(self) weakSelf = self;
    confirm.confirmFollowUpAction = ^(NSArray *confirmedAssets) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        NSInteger idx = 0;
        ObservationPhoto *op = self.observation.sortedObservationPhotos.lastObject;
        if (op) {
            idx = op.position.integerValue + 1;
        }
        for (UIImage *image in confirmedAssets) {
            ObservationPhoto *op = [ObservationPhoto object];
            op.position = @(idx);
            [op setObservation:strongSelf.observation];
            [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
            
            NSError *saveError = nil;
            BOOL saved = [[ImageStore sharedImageStore] storeImage:image
                                                            forKey:op.photoKey
                                                             error:&saveError];
            if (saveError) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg")
                                            message:saveError.localizedDescription
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                  otherButtonTitles:nil] show];
                [op destroy];
                return;
            } else if (!saved) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg")
                                            message:NSLocalizedString(@"Unknown error", @"Message body when we don't know the error")
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                  otherButtonTitles:nil] show];
                [op destroy];
                return;
            }
            
            op.localCreatedAt = [NSDate date];
            op.localUpdatedAt = [NSDate date];
            
            idx++;
        }
        
        [strongSelf dismissViewControllerAnimated:YES completion:nil];
    };
    
    UINavigationController *nav = (UINavigationController *)self.presentedViewController;
    [nav pushViewController:confirm animated:YES];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    ConfirmPhotoViewController *confirm = [[ConfirmPhotoViewController alloc] initWithNibName:nil bundle:nil];
    confirm.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    confirm.metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationAddPhoto
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"Source": @"Camera",
                                      @"Count": @(1)
                                      }];
    
    // set the follow up action
    __weak typeof(self)weakSelf = self;
    confirm.confirmFollowUpAction = ^(NSArray *assets) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        NSInteger idx = 0;
        ObservationPhoto *lastOp = [[self.observation sortedObservationPhotos] lastObject];
        if (lastOp) {
            idx = [[lastOp position] integerValue] + 1;
        }
        for (UIImage *image in assets) {
            ObservationPhoto *op = [ObservationPhoto object];
            op.position = @(idx);
            [op setObservation:strongSelf.observation];
            [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
            
            NSError *saveError = nil;
            BOOL saved = [[ImageStore sharedImageStore] storeImage:image
                                                            forKey:op.photoKey
                                                             error:&saveError];
            NSString *saveErrorTitle = NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg");
            if (saveError) {
                [op destroy];
                [self dismissViewControllerAnimated:YES completion:^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveErrorTitle
                                                                                   message:saveError.localizedDescription
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil]];
                    [strongSelf presentViewController:alert animated:YES completion:nil];
                }];
                return;
            } else if (!saved) {
                [op destroy];
                [self dismissViewControllerAnimated:YES completion:^{
                    NSString *unknownErrMsg = NSLocalizedString(@"Unknown error", @"Message body when we don't know the error");
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveErrorTitle
                                                                                   message:unknownErrMsg
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil]];
                    [strongSelf presentViewController:alert animated:YES completion:nil];
                }];
                return;
            }
            
            op.localCreatedAt = [NSDate date];
            op.localUpdatedAt = [NSDate date];
            
            idx++;
        }
        
        [strongSelf.tableView reloadData];
        [strongSelf dismissViewControllerAnimated:YES completion:nil];
    };
    
    [picker pushViewController:confirm animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // workaround for a crash in Apple's didHideZoomSlider
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [[Analytics sharedClient] event:kAnalyticsEventLocationPermissionsChanged
                     withProperties:@{
                                      @"Via": NSStringFromClass(self.class),
                                      @"NewValue": @(status),
                                      }];

    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (self.shouldContinueUpdatingLocation) {
                [self startUpdatingLocation];
            }
            break;
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Location Services Denied", nil)
                                                                           message:NSLocalizedString(@"Cannot use your location", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
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
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[ ip ] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
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
    self.shouldContinueUpdatingLocation = NO;
    [self.locationManager stopUpdatingLocation];
}

- (void)startUpdatingLocation {
    [self.locationManager startUpdatingLocation];
}


#pragma mark - geocoding helper

- (void)reverseGeocodeCoordinatesForObservation:(Observation *)obs {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
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
                                    obs.localUpdatedAt = [NSDate date];
                                    NSIndexPath *locRowIp = [NSIndexPath indexPathForItem:2 inSection:ConfirmObsSectionNotes];
                                    [self.tableView beginUpdates];
                                    [self.tableView reloadRowsAtIndexPaths:@[ locRowIp ]
                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                                    [self.tableView endUpdates];
                                } @catch (NSException *exception) {
                                    if ([exception.name isEqualToString:NSObjectInaccessibleException])
                                        return;
                                    else
                                        @throw exception;
                                }
                            }
                        }];
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
    self.observation.localUpdatedAt = [NSDate date];
    
    NSIndexPath *speciesIndexPath = [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionIdentify];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ speciesIndexPath ]
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)cancelledNewObservation:(UIBarButtonItem *)item {
    [self stopUpdatingLocation];
    
    if (self.isMakingNewObservation) {
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationCancel];
        
        [self stopUpdatingLocation];
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
    UIAlertController *alert = nil;
    
    if (!self.observation.taxonID && !self.observation.speciesGuess && self.observation.observationPhotos.count == 0) {
        // alert about the combo of no photos and no taxon/species guess being bad
        NSString *title = NSLocalizedString(@"No Photos and Missing Identification", nil);
        NSString *msg = NSLocalizedString(@"Without at least one photo, this observation will be impossible for others to help identify.", nil);
        alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    } else if (!self.observation.localObservedOn) {
        // alert about no date
        NSString *title = NSLocalizedString(@"Missing Date", nil);
        NSString *msg = NSLocalizedString(@"Without a date, this observation may be very hard for others to identify accurately, and will never attain research grade.", nil);
        alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    } else if (!self.observation.latitude) {
        // alert about no location
        NSString *title = NSLocalizedString(@"Missing Location", nil);
        NSString *msg = NSLocalizedString(@"Without a location, this observation will be very hard for others to identify and will never attain research grade.", nil);
        alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    }
    if (alert) {
        // finish configuring the alert
        UIAlertAction* saveAnyway = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save Anyway", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self validatedSave];
        }];
        [alert addAction:saveAnyway];
        
        UIAlertAction* goBack = [UIAlertAction actionWithTitle:NSLocalizedString(@"Go Back", nil) style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:goBack];
        
        // show the alert
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // good to go
        [self validatedSave];
    }
}

- (void)validatedSave {
    [self.view endEditing:YES];
    
    [self stopUpdatingLocation];
    
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationSaveObservation
                     withProperties:@{
                                      @"Via": [self analyticsVia],
                                      @"Projects": @(self.observation.projectObservations.count),
                                      @"Photos": @(self.observation.observationPhotos.count),
                                      @"OFVs": @(self.observation.observationFieldValues.count)
                                      }];
        
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
            ofv.localUpdatedAt = [NSDate date];
            ofv.localCreatedAt = [NSDate date];
        }
        
        po.localUpdatedAt = [NSDate date];
        po.localCreatedAt = [NSDate date];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Taxa Search

- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxon chosenViaVision:(BOOL)visionFlag {
    self.observation.taxonID = @(taxon.taxonId);
    self.observation.localUpdatedAt = [NSDate date];
    self.observation.ownersIdentificationFromVision = @(visionFlag);
    
    NSString *newTaxonName = taxon.commonName ?: taxon.scientificName;
    if (!newTaxonName) { newTaxonName = NSLocalizedString(@"Unknown", @"unknown taxon"); }
    
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

- (void)taxaSearchViewControllerCancelled {
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - EditLocationDelegate

- (void)editLocationViewControllerDidSave:(EditLocationViewController *)controller location:(INatLocation *)location {
    
    [self stopUpdatingLocation];
    
    if (location.latitude.integerValue == 0 && location.longitude.integerValue == 0) {
        // nothing happens on null island
        self.observation.latitude = nil;
        self.observation.longitude = nil;
        self.observation.positionalAccuracy = nil;
        self.observation.positioningMethod = nil;
        self.observation.placeGuess = nil;
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
            return 1;
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
            return 130;
            break;
        case ConfirmObsSectionIdentify:
            return 60;
        case ConfirmObsSectionNotes:
            if (indexPath.item == 0) {
                // notes
                return 66;
            } else if (indexPath.item == 1) {
                // datetime
                return 44;
            } else if (indexPath.item == 2) {
                // location
                CLLocationCoordinate2D coords = kCLLocationCoordinate2DInvalid;
                
                if (self.observation.privateLatitude.floatValue) {
                    coords = CLLocationCoordinate2DMake(self.observation.privateLatitude.floatValue, self.observation.privateLongitude.floatValue);
                } else if (self.observation.latitude.floatValue) {
                    coords = CLLocationCoordinate2DMake(self.observation.latitude.floatValue, self.observation.longitude.floatValue);
                }
                
                return CLLocationCoordinate2DIsValid(coords) ? 66 : 44;
                
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
        case ConfirmObsSectionIdentify:
            return 0;
            break;
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
            return [self speciesCellInTableView:tableView];
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
                // only prime the query if there's a placeholder, not a taxon)
                if (self.observation.speciesGuess && !self.observation.taxonID) {
                    search.query = self.observation.speciesGuess;
                }
                search.allowsFreeTextSelection = YES;
                
                if (self.observation.observationPhotos.count > 0) {
                    ObservationPhoto *op = [self.observation.sortedObservationPhotos firstObject];
                    NSString *imgKey = [op photoKey];
                    if (imgKey) {
                        UIImage *image = [[ImageStore sharedImageStore] find:imgKey forSize:ImageStoreSmallSize];
                        search.imageToClassify = image;
                    }
                    if (!search.imageToClassify) {
                        // if we couldn't find it in the imagestore,
                        // try to load it from the afnetworking caches
                        NSURLRequest *request = [NSURLRequest requestWithURL:op.smallPhotoUrl];
                        UIImage *image = [[UIImageView sharedImageCache] cachedImageForRequest:request];
                        if (image) {
                            search.imageToClassify = image;
                        } else if ([self.observation recordID]) {
                            // if we _still_ can't find an image, and the obs has been uploaded
                            // to inat, try classifying the observation by id
                            search.observationToClassify = self.observation;
                        }
                    }
                    
                    if (search.imageToClassify) {
                        if (CLLocationCoordinate2DIsValid(self.observation.visibleLocation)) {
                            search.coordinate = self.observation.visibleLocation;
                        }
                        if (self.observation.observedOn) {
                            search.observedOn = self.observation.observedOn;
                        }
                    }
                }
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
                                                 selectedDate:self.observation.localObservedOn ?: [NSDate date]
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
                                                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                                                           message:alertMsg
                                                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                                                            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                                                      style:UIAlertActionStyleCancel
                                                                                                    handler:nil]];
                                                            [weakSelf presentViewController:alert animated:YES completion:nil];
                                                            return;
                                                        }
                                                        
                                                        [[Analytics sharedClient] event:kAnalyticsEventObservationDateChanged\
                                                                         withProperties:@{
                                                                                          @"Via": [self analyticsVia]
                                                                                          }];
                                                        
                                                        
                                                        __strong typeof(weakSelf) strongSelf = self;
                                                        strongSelf.observation.localObservedOn = date;
                                                        strongSelf.observation.observedOnString = [Observation.jsDateFormatter stringFromDate:date];
                                                        strongSelf.observation.localUpdatedAt = [NSDate date];
                                                        
                                                        [strongSelf.tableView beginUpdates];
                                                        [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                    withRowAnimation:UITableViewRowAnimationFade];
                                                        [strongSelf.tableView endUpdates];
                                                        
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
                                                          strongSelf.observation.localUpdatedAt = [NSDate date];
                                                          
                                                          [[Analytics sharedClient] event:kAnalyticsEventObservationGeoprivacyChanged
                                                                           withProperties:@{ @"Via": [self analyticsVia],
                                                                                             @"New Value": newValue}];
                                                          
                                                          [strongSelf.tableView beginUpdates];
                                                          [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                      withRowAnimation:UITableViewRowAnimationFade];
                                                          [strongSelf.tableView endUpdates];
                                                          
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
                                                          strongSelf.observation.localUpdatedAt = [NSDate date];
                                                          
                                                          [strongSelf.tableView beginUpdates];
                                                          [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                      withRowAnimation:UITableViewRowAnimationFade];
                                                          [strongSelf.tableView endUpdates];
                                                          
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
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"You must be logged in!", nil)
                                                                                   message:NSLocalizedString(@"You must be logged in to access projects.", nil)
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];                    
                }
                
                
            } else {
                // do nothing
            }
            break;
        case ConfirmObsSectionDelete: {
            // show alertview
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure? This is permanent.", nil)
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Never mind",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes, delete this observation",nil)
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [self deleteThisObservation];
                                                    }]];

            [self presentViewController:alert animated:YES completion:nil];
        }
            
            break;
        default:
            // do nothing
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
    
    ObsDetailTaxonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxonFromNib"];
    
    UIButton *deleteButton = ({
        FAKIcon *deleteIcon = [FAKIonIcons iosCloseIconWithSize:29];
        [deleteIcon addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [button setAttributedTitle:deleteIcon.attributedString forState:UIControlStateNormal];
        [button addTarget:self action:@selector(taxonDeleted:) forControlEvents:UIControlEventTouchUpInside];
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        
        button;
    });
    
    cell.taxonNameLabel.textColor = [UIColor blackColor];
    cell.taxonSecondaryNameLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    RLMResults *results = [ExploreTaxonRealm objectsWhere:@"taxonId == %d", self.observation.taxonID.integerValue];
    
    if (results.count == 1) {
        ExploreTaxonRealm *etr = [results firstObject];
        if (!etr.commonName || [etr.commonName isEqualToString:etr.scientificName]) {
            // no common name, so only show scientific name in the main label
            cell.taxonNameLabel.text = etr.scientificName;
            cell.taxonSecondaryNameLabel.text = nil;
            
            if (etr.isGenusOrLower) {
                cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:17];
                cell.taxonNameLabel.text = etr.scientificName;
            } else {
                cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
                cell.taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                            [etr.rankName capitalizedString], etr.scientificName];
            }
        } else {
            // show both common & scientfic names
            cell.taxonNameLabel.text = etr.commonName;
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            
            if (etr.isGenusOrLower) {
                cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:14];
                cell.taxonSecondaryNameLabel.text = etr.scientificName;
            } else {
                cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
                cell.taxonSecondaryNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                                     [etr.rankName capitalizedString], etr.scientificName];
                
            }
        }
        
        if ([etr.iconicTaxonName isEqualToString:etr.commonName]) {
            cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:etr.iconicTaxonName];
        } else if (etr.photoUrl) {
            [cell.taxonImageView setImageWithURL:etr.photoUrl];
        } else {
            cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:etr.iconicTaxonName];
        }
        
        cell.accessoryView = deleteButton;
    } else {
        FAKIcon *question = [FAKINaturalist speciesUnknownIconWithSize:44];
        [question addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
        cell.taxonImageView.image = [question imageWithSize:CGSizeMake(44, 44)];
        // the question icon has a rendered border
        cell.taxonImageView.layer.borderWidth = 0.0f;
        
        if (self.observation.speciesGuess) {
            cell.taxonNameLabel.text = self.observation.speciesGuess;
        } else {
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            cell.taxonNameLabel.textColor = [UIColor colorWithHexString:@"#777777"];
            cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
            cell.taxonSecondaryNameLabel.textColor = [UIColor colorWithHexString:@"#777777"];
            cell.taxonNameLabel.text = NSLocalizedString(@"What did you see?", @"unknown taxon title");
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kINatSuggestionsPrefKey] &&
                self.observation.sortedObservationPhotos.count > 0) {
                cell.taxonSecondaryNameLabel.text = NSLocalizedString(@"View suggestions",
                                                                      @"unknown taxon subtitle when suggestions are available");
            } else {
                cell.taxonSecondaryNameLabel.text = NSLocalizedString(@"Look up species name",
                                                                      @"unknown taxon subtitle when suggestions are unavailable");
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
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
    
    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(-19999.0, -19999.0);
    
    if (self.observation.visibleLatitude) {
        coords = CLLocationCoordinate2DMake(self.observation.visibleLatitude.doubleValue, self.observation.visibleLongitude.doubleValue);
    }
    
    if (CLLocationCoordinate2DIsValid(coords)) {
        SubtitleDisclosureCell *subtitleCell = [tableView dequeueReusableCellWithIdentifier:@"subtitleDisclosure"];
        cell = subtitleCell;
        
        NSString *positionalAccuracy = nil;
        if (self.observation.positionalAccuracy) {
            positionalAccuracy = [NSString stringWithFormat:@"%ld m", (long)self.observation.positionalAccuracy.integerValue];
        } else {
            positionalAccuracy = NSLocalizedString(@"???", @"positional accuracy when we don't know");
        }
        NSString *subtitleString = [NSString stringWithFormat:@"Lat: %.3f  Long: %.3f  Acc: %@",
                                    coords.latitude,
                                    coords.longitude,
                                    positionalAccuracy];
        subtitleCell.subtitleLabel.text = subtitleString;
        
        if (self.observation.placeGuess && self.observation.placeGuess.length > 0) {
            subtitleCell.titleLabel.text = self.observation.placeGuess;
        } else {
            subtitleCell.titleLabel.text = NSLocalizedString(@"Unable to find location name", @"place guess when we have lat/lng but it's not geocoded");
            // only try to persistently, passively geocode a placeguess if this is a new observation
            if (self.isMakingNewObservation) {
                [self reverseGeocodeCoordinatesForObservation:self.observation];
            }
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
