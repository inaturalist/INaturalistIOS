//
//  ConfirmObservationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

@import AVKit;
@import AFNetworking;
@import FontAwesomeKit;
@import ActionSheetPicker_3_0;
@import BlocksKit;
@import ImageIO;
@import UIColor_HTMLColors;
@import JDStatusBarNotification;
@import MHVideoPhotoGallery;
@import PhotosUI;


#import "ObsEditV2ViewController.h"
#import "ExploreTaxonRealm.h"
#import "ImageStore.h"
#import "UIColor+INaturalist.h"
#import "DisclosureCell.h"
#import "TaxaSearchViewController.h"
#import "TextViewCell.h"
#import "EditLocationViewController.h"
#import "SubtitleDisclosureCell.h"
#import "ObsCameraOverlay.h"
#import "ConfirmPhotoViewController.h"
#import "FAKINaturalist.h"
#import "ObservationFieldValue.h"
#import "ProjectObservationsViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "UploadManager.h"
#import "Analytics.h"
#import "MediaScrollViewCell.h"
#import "ObsCenteredLabelCell.h"
#import "ObsDetailTaxonCell.h"
#import "ExploreUpdateRealm.h"
#import "INatReachability.h"
#import "UIViewController+INaturalist.h"
#import "CLPlacemark+INat.h"
#import "ExploreObservationRealm.h"
#import "ExploreDeletedRecord.h"
#import "iNaturalist-Swift.h"
#import "CLLocation+EXIFGPSDictionary.h"
#import "UIImage+INaturalist.h"

typedef NS_ENUM(NSInteger, ConfirmObsSection) {
    ConfirmObsSectionPhotos = 0,
    ConfirmObsSectionIdentify,
    ConfirmObsSectionNotes,
    ConfirmObsSectionDelete,
};

@interface ObsEditV2ViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, EditLocationViewControllerDelegate, MediaScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TaxaSearchViewControllerDelegate, CLLocationManagerDelegate, GalleryWrapperDelegate, MediaPickerDelegate, PHPickerViewControllerDelegate, SoundRecorderDelegate> {
    
    CLLocationManager *_locationManager;
}
@property UIButton *saveButton;
@property (readonly) NSString *notesPlaceholder;
@property (readonly) CLLocationManager *locationManager;
@property UITapGestureRecognizer *tapDismissTextViewGesture;
@property CLGeocoder *geoCoder;
@property NSMutableArray *recordsToDelete;
@property GalleryWrapper *galleryWrapper;
@property (nonatomic, strong) SlideInPresentationManager *slideInPresentationManager;

@end

@implementation ObsEditV2ViewController

#pragma mark MediaPickerDelegate

- (void)choseMediaPickerItemAtIndex:(NSInteger)idx {
    if (idx == 0) {
        [self dismissViewControllerAnimated:YES completion:^{
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.mediaTypes = @[ @"public.image" ];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:picker animated:YES completion:nil];
        }];
    } else if (idx == 1) {
        // dismiss the media picker, present the gallery
        [self dismissViewControllerAnimated:YES completion:^{
            if (@available(iOS 14.0, *)) {
                PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
                config.selectionLimit = 4;
                config.filter = PHPickerFilter.imagesFilter;
                
                PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
                picker.delegate = self;
                [self presentViewController:picker animated:YES completion:nil];
            } else {
                UIViewController *gallery = self.galleryWrapper.gallery;
                [self presentViewController:gallery animated:YES completion:nil];
            }
        }];
    } else if (idx == 2) {
        // dismiss the media picker, present the sound recorder
        [self dismissViewControllerAnimated:YES completion:^{
            SoundRecordViewController *recorder = [[SoundRecordViewController alloc] initWithNibName:nil bundle:nil];
            recorder.recorderDelegate = self;
            UINavigationController *soundNav = [[UINavigationController alloc] initWithRootViewController:recorder];
            [self presentViewController:soundNav animated:YES completion:nil];
        }];
    }
}

// lazy variable
- (SlideInPresentationManager *)slideInPresentationManager {
    if (_slideInPresentationManager == nil) {
        _slideInPresentationManager = [[SlideInPresentationManager alloc] init];
    }
    return _slideInPresentationManager;
}

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
    
    self.view.backgroundColor = [UIColor inatTableViewBackgroundGray];
    
    self.tableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        tv.dataSource = self;
        tv.delegate = self;
        
        [tv registerClass:[DisclosureCell class] forCellReuseIdentifier:@"disclosure"];
        [tv registerClass:[SubtitleDisclosureCell class] forCellReuseIdentifier:@"subtitleDisclosure"];
        [tv registerClass:[MediaScrollViewCell class] forCellReuseIdentifier:@"media"];
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
    
    self.title = NSLocalizedString(@"Details", @"Title for confirm new observation details view");
    
    // finish configuring subviews based on new obs context
    if (self.isMakingNewObservation) {
        // new obs confirm has no Done nav bar button
        self.navigationItem.rightBarButtonItem = nil;
        
        // new obs confirm has a save button
        [self.view addSubview:self.saveButton];
    } else {
        // save existing obs has a Done nav bar button
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(saved:)];
    }
    
    // autolayout
    UILayoutGuide *safeGuide = [self inat_safeLayoutGuide];
    // horizontal
    [self.tableView.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [self.tableView.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    
    if (self.isMakingNewObservation) {
        // horizontal
        [self.saveButton.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
        [self.saveButton.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
        
        // vertical
        [self.tableView.topAnchor constraintEqualToAnchor:safeGuide.topAnchor].active = YES;
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.saveButton.topAnchor].active = YES;
        [self.saveButton.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor].active = YES;
        [self.saveButton.heightAnchor constraintEqualToConstant:47.0f].active = YES;
    } else {
        // vertical
        [self.tableView.topAnchor constraintEqualToAnchor:safeGuide.topAnchor].active = YES;
        [self.tableView.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor].active = YES;
    }
    
    if (!self.standaloneObservation && self.persistedObservation) {
        // standalone copy of the observation, with copies of the photos
        // so that we can delete or re-order photos as needed.
        self.standaloneObservation = [self.persistedObservation standaloneCopyWithMedia];
    }
    
    self.recordsToDelete = [NSMutableArray array];
    self.galleryWrapper = [[GalleryWrapper alloc] init];
    self.galleryWrapper.wrapperDelegate = self;
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
    
    // don't use property here
    if (_locationManager) {
        [_locationManager stopUpdatingLocation];
    }
}

- (void)deleteThisObservation {
    // delete this observation
    [[Analytics sharedClient] event:kAnalyticsEventObservationDelete];
    
    // delete all related updates
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    NSString *predString = [NSString stringWithFormat:@"resourceId == %ld",
                            (unsigned long)self.persistedObservation.observationId];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predString];
    RLMResults *results = [ExploreUpdateRealm objectsWithPredicate:predicate];
    [realm deleteObjects:results];
    [realm commitWriteTransaction];
    
    // pop to the root view controller
    // dispatch/enqueue this to allow the popover controller on ipad
    // (which presents the action sheet) to dismiss first
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarController *tab = (UITabBarController *)self.presentingViewController;
        UINavigationController *nav = (UINavigationController *)tab.selectedViewController;
        
        [tab dismissViewControllerAnimated:YES completion:^{
            [nav popToRootViewControllerAnimated:NO];
            
            // if it's ever been synced
            if (self.persistedObservation.timeSynced) {
                [ExploreObservationRealm syncedDelete:self.persistedObservation];
            } else {
                [ExploreObservationRealm deleteWithoutSync:self.persistedObservation];
            }
            
            // trigger the delete to happen on the server
            
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
        }];
    });
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
    if (![textView.text isEqualToString:self.standaloneObservation.inatDescription]) {
        // text changed
        self.standaloneObservation.inatDescription = textView.text;
        self.standaloneObservation.timeUpdatedLocally = [NSDate date];
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

#pragma mark - MediaScrollViewDelegate

- (void)mediaScrollView:(MediaScrollViewCell *)psv setDefaultIndex:(NSInteger)idx {
    // this happens entirely within photos, sounds are simply placed at the end
    // and have no position in the API
    // create a copy of sorted photos so we can re-order stuff safely
    NSMutableArray *photosCopy = [self.standaloneObservation.sortedObservationPhotos mutableCopy];
    // move the new default to the beginning of the copied array
    ExploreObservationPhotoRealm *newDefault = [photosCopy objectAtIndex:idx];
    [photosCopy removeObject:newDefault];
    [photosCopy insertObject:newDefault atIndex:0];
    
    // set the index of the item in the copied array to the position on the obsPhoto
    // object. this will direct sortedObservationPhotos on the app and on the web.
    for (int i = 0; i < photosCopy.count; i++) {
        ExploreObservationPhotoRealm *op = photosCopy[i];
        if (op.position == i) { continue; }
        op.position = i;
        op.timeUpdatedLocally = [NSDate date];
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationNewDefaultPhoto
                     withProperties:@{ @"Via": [self analyticsVia] }];
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionPhotos] ]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)mediaScrollView:(MediaScrollViewCell *)psv deletedIndex:(NSInteger)idx {
    id recordToDelete = [[self.standaloneObservation observationMedia] objectAtIndex:idx];
    // stash it for deletion when we save
    [self.recordsToDelete addObject:recordToDelete];
    
    if ([recordToDelete isKindOfClass:ExploreObservationPhotoRealm.class]) {
        NSInteger indexOfPhoto = [self.standaloneObservation.observationPhotos indexOfObject:recordToDelete];
        [self.standaloneObservation.observationPhotos removeObjectAtIndex:indexOfPhoto];
        
        // update sortable
        for (int i = 0; i < self.standaloneObservation.sortedObservationPhotos.count; i++) {
            ExploreObservationPhotoRealm *op = self.standaloneObservation.sortedObservationPhotos[i];
            op.position = i;
            op.timeUpdatedLocally = [NSDate date];
        }
    } else if ([recordToDelete isKindOfClass:ExploreObservationSoundRealm.class]) {
        NSInteger indexOfSound = [self.standaloneObservation.observationSounds indexOfObject:recordToDelete];
        [self.standaloneObservation.observationSounds removeObjectAtIndex:indexOfSound];
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationDeletePhoto
                     withProperties:@{ @"Via": [self analyticsVia] }];
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionPhotos] ]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)mediaScrollView:(MediaScrollViewCell *)psv selectedIndex:(NSInteger)idx {
    id selectedRecord = [self.standaloneObservation.observationMedia objectAtIndex:idx];
    
    if ([selectedRecord isKindOfClass:ExploreObservationPhotoRealm.class]) {
        // open the gallery with this photo showing
        NSArray *galleryData = [self.standaloneObservation.sortedObservationPhotos bk_map:^id(ExploreObservationPhotoRealm *op) {
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

    } else if ([selectedRecord isKindOfClass:ExploreObservationSoundRealm.class]) {
        
        NSURL *soundUrl = nil;
        
        id <INatSound> sound = (id <INatSound>)selectedRecord;
        MediaStore *ms = [[MediaStore alloc] init];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *localMediaUrl = [ms mediaUrlForKey:sound.mediaKey];
        if (localMediaUrl && [fm fileExistsAtPath:localMediaUrl.path]) {
            soundUrl = localMediaUrl;
        } else {
            soundUrl = [sound mediaUrl];
        }
        
        // request speaker audio output
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        BOOL categorySuccess = [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        BOOL overrideSuccess = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                          error:&error];
        if (categorySuccess && overrideSuccess && !error) {
            [session setActive:YES error:&error];
        }

        AVPlayer *player = [[AVPlayer alloc] initWithURL:soundUrl];
        AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] initWithNibName:nil bundle:nil];
        playerVC.player = player;
        
        [self presentViewController:playerVC animated:YES completion:^{
            [player play];
        }];
    }
}

- (void)mediaScrollViewAddPressed:(MediaScrollViewCell *)psv {
    MediaPickerViewController *mediaPicker = [[MediaPickerViewController alloc] init];
    mediaPicker.mediaPickerDelegate = self;
    mediaPicker.showsNoPhotoOption = NO;
    mediaPicker.modalPresentationStyle = UIModalPresentationCustom;
    mediaPicker.transitioningDelegate = self.slideInPresentationManager;
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelelgate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results  API_AVAILABLE(ios(14)){
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if (results.count == 0) {
        // user cancelled
        return;
    }

    NSInteger idx = 0;
    ExploreObservationPhotoRealm *lastOp = [[self.standaloneObservation sortedObservationPhotos] lastObject];
    if (lastOp) {
        idx = lastOp.position + 1;
    }
    
    for (PHPickerResult *result in results) {
        // each result gets a new index in order of the results,
        // not in order of the load (which might return out of
        // order?)
        idx = [results indexOfObject:result] + idx;
        if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
            
            [result.itemProvider loadObjectOfClass:[UIImage class]
                                 completionHandler:^(UIImage *image, NSError * _Nullable loadError) {
                
                if (loadError) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *saveErrorTitle = NSLocalizedString(@"Photo Load Error", @"Title for photo load error alert msg");
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveErrorTitle
                                                                                       message:loadError.localizedDescription
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                    return;
                }
                
                if (!image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *photosErrorTitle = NSLocalizedString(@"Photos Error", @"Title for photos error alert msg");
                        NSString *unknownErrMsg = NSLocalizedString(@"Unknown error", @"Message body when we don't know the error");
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:photosErrorTitle
                                                                                       message:unknownErrMsg
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                    return;
                }
                
                ImageStore *store = [ImageStore sharedImageStore];
                NSString *photoKey = [store createKey];
                NSError *error = nil;
                [store storeImage:image forKey:photoKey error:&error];
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *saveErrorTitle = NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg");
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveErrorTitle
                                                                                       message:error.localizedDescription
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                    return;
                }
                
                
                // this callback comes off the main thread, but we need to do realm work on the main thread,
                // so jump over now
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    ExploreObservationPhotoRealm *op = [ExploreObservationPhotoRealm new];
                    op.position = idx;
                    op.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
                    [op setPhotoKey:photoKey];
                    
                    op.timeCreated = [NSDate date];
                    op.timeUpdatedLocally = [NSDate date];
                    
                    if (self.standaloneObservation.observationPhotos.realm) {
                        // the standalone observation shouldn't be in realm, but this can
                        // happen when the observation is saved and and iCloud fetch is in flight
                        // don't crash in this race condition
                        RLMRealm *realm = self.standaloneObservation.observationPhotos.realm;
                        [realm beginWriteTransaction];
                        [self.standaloneObservation.observationPhotos addObject:op];
                        [realm commitWriteTransaction];
                    } else {
                        [self.standaloneObservation.observationPhotos addObject:op];
                    }
                    [self.tableView reloadData];
                });
            }];
        }
    }
}

#pragma mark - SoundRecorderDelegate

- (void)recordedSoundWithRecorder:(SoundRecordViewController *)recorder uuidString:(NSString *)uuidString {
    ExploreObservationSoundRealm *obsSound = [[ExploreObservationSoundRealm alloc] init];
    obsSound.uuid = uuidString;
    obsSound.timeUpdatedLocally = [NSDate date];
    
    [self.standaloneObservation.observationSounds addObject:obsSound];
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelledWithRecorder:(SoundRecordViewController *)recorder {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (!image) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    NSMutableDictionary *mutableMetadata = [[info objectForKey:UIImagePickerControllerMediaMetadata] mutableCopy];
    NSData *imageData = nil;
    if (mutableMetadata) {
        CLLocation *location = [self.locationManager location];
        if (location.timestamp.timeIntervalSinceNow > -300) {
            NSDictionary *gpsDict = [location inat_GPSDictionary];
            mutableMetadata[(NSString *)kCGImagePropertyGPSDictionary] = gpsDict;
        }
        NSDictionary *metadata = [NSDictionary dictionaryWithDictionary:mutableMetadata];
        imageData = [image inat_JPEGDataRepresentationWithMetadata:metadata quality:0.9];
    } else {
        imageData = UIImageJPEGRepresentation(image, 0.9);
    }
    
    if (imageData != nil) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
            [request addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
            [request setCreationDate:[NSDate date]];
            
            CLLocation *location = self.locationManager.location;
            if (location && location.timestamp.timeIntervalSinceNow > -300) {
                [request setLocation:location];
            }
        } error:nil];               // silently continue if this save operation fails
    }
    
    NSInteger idx = 0;
    ExploreObservationPhotoRealm *lastOp = [[self.standaloneObservation sortedObservationPhotos] lastObject];
    if (lastOp) {
        idx = lastOp.position + 1;
    }
    
    ExploreObservationPhotoRealm *op = [ExploreObservationPhotoRealm new];
    op.position = idx;
    op.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
    [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
    
    NSError *saveError = nil;
    BOOL saved = [[ImageStore sharedImageStore] storeImage:image
                                                    forKey:op.photoKey
                                                     error:&saveError];
    
    NSString *saveErrorTitle = NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg");
    if (saveError) {
        [self dismissViewControllerAnimated:YES completion:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveErrorTitle
                                                                           message:saveError.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }];
        return;
    } else if (!saved) {
        [self dismissViewControllerAnimated:YES completion:^{
            NSString *unknownErrMsg = NSLocalizedString(@"Unknown error", @"Message body when we don't know the error");
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveErrorTitle
                                                                           message:unknownErrMsg
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }];
        return;
    }
    
    op.timeCreated = [NSDate date];
    op.timeUpdatedLocally = [NSDate date];
    
    [self.standaloneObservation.observationPhotos addObject:op];
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - GalleryWrapperDelegate methods

- (void)galleryDidSelect:(NSArray<UIImage *> *)images {
    NSInteger idx = 0;
    ExploreObservationPhotoRealm *lastOp = [[self.standaloneObservation sortedObservationPhotos] lastObject];
    if (lastOp) {
        idx = lastOp.position + 1;
    }
    for (UIImage *image in images) {
        ExploreObservationPhotoRealm *op = [ExploreObservationPhotoRealm new];
        op.position = idx;
        op.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
        [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
        
        NSError *saveError = nil;
        BOOL saved = [[ImageStore sharedImageStore] storeImage:image
                                                        forKey:op.photoKey
                                                         error:&saveError];
        
        NSString *saveErrorTitle = NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg");
        if (saveError) {
            [self dismissViewControllerAnimated:YES completion:^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveErrorTitle
                                                                               message:saveError.localizedDescription
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }];
            return;
        } else if (!saved) {
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *unknownErrMsg = NSLocalizedString(@"Unknown error", @"Message body when we don't know the error");
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:saveErrorTitle
                                                                               message:unknownErrMsg
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }];
            return;
        }
        
        op.timeCreated = [NSDate date];
        op.timeUpdatedLocally = [NSDate date];
        
        [self.standaloneObservation.observationPhotos addObject:op];
        
        idx++;
    }
    
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)galleryDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    if (!self.standaloneObservation) return;
    
    // if observation has been saved & added to realm, bail here
    // don't update data model when they're not shown on screen for
    // the user.
    if (self.standaloneObservation.realm) return;
    
    @try {
        self.standaloneObservation.latitude = newLocation.coordinate.latitude;
        self.standaloneObservation.longitude = newLocation.coordinate.longitude;
        self.standaloneObservation.privatePositionalAccuracy = newLocation.horizontalAccuracy;
        // TODO: do we need this?
        //self.observation.positioningMethod = @"gps";
        
        self.standaloneObservation.timeUpdatedLocally = [NSDate date];
        
        NSIndexPath *ip = [NSIndexPath indexPathForItem:2 inSection:ConfirmObsSectionNotes];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                              withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        
        if (newLocation.horizontalAccuracy < 10) {
            self.shouldContinueUpdatingLocation = NO;
            [self stopUpdatingLocation];
        }
        
        if (self.standaloneObservation.placeGuess.length == 0 || !oldLocation || [newLocation distanceFromLocation:oldLocation] > 100) {
            [self reverseGeocodeCoordinatesForObservation:self.standaloneObservation];
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

- (void)reverseGeocodeCoordinatesForObservation:(ExploreObservationRealm *)obs {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        return;
    }
    
    if (!self.geoCoder) {
        self.geoCoder = [[CLGeocoder alloc] init];
    }
    
    [self.geoCoder cancelGeocode];       // cancel anything in flight
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:obs.latitude longitude:obs.longitude];
    
    __weak typeof(self) weakSelf = self;
    [self.geoCoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (!weakSelf) {
            return;
        }
        
        CLPlacemark *placemark = [placemarks firstObject];
        if (placemark) {
            @try {
                // this can come in after we've added the observation
                // to realm, so do it in a transaction
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                obs.placeGuess = [placemark inatPlaceGuess];
                obs.timeUpdatedLocally = [NSDate date];
                [realm commitWriteTransaction];
                NSIndexPath *locRowIp = [NSIndexPath indexPathForItem:2 inSection:ConfirmObsSectionNotes];
                [weakSelf.tableView beginUpdates];
                [weakSelf.tableView reloadRowsAtIndexPaths:@[ locRowIp ]
                                          withRowAnimation:UITableViewRowAnimationNone];
                [weakSelf.tableView endUpdates];
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
    
    self.standaloneObservation.speciesGuess = nil;
    self.standaloneObservation.taxon = nil;
    self.standaloneObservation.timeUpdatedLocally = [NSDate date];
    
    NSIndexPath *speciesIndexPath = [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionIdentify];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ speciesIndexPath ]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)cancelledNewObservation:(UIBarButtonItem *)item {
    self.shouldContinueUpdatingLocation = NO;
    [self stopUpdatingLocation];
    
    if (self.isMakingNewObservation) {
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationCancel];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)saved:(UIButton *)button {
    UIAlertController *alert = nil;
    
    if (!self.standaloneObservation.taxon && !self.standaloneObservation.speciesGuess && self.standaloneObservation.observationMedia.count == 0) {
        // alert about the combo of no photos and no taxon/species guess being bad
        NSString *title = NSLocalizedString(@"No Photos or Sounds and Missing Identification", nil);
        NSString *msg = NSLocalizedString(@"Without at least one photo or sound, this observation will be impossible for others to help identify.", nil);
        alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    } else if (!self.standaloneObservation.timeObserved) {
        // alert about no date
        NSString *title = NSLocalizedString(@"Missing Date", nil);
        NSString *msg = NSLocalizedString(@"Without a date, this observation may be very hard for others to identify accurately, and will never attain research grade.", nil);
        alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    } else if (!CLLocationCoordinate2DIsValid(self.standaloneObservation.location)) {
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
    
    self.shouldContinueUpdatingLocation = NO;
    [self stopUpdatingLocation];
    
    // clear upload validation error message
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        self.standaloneObservation.validationErrorMsg = nil;
    }];
    
    if (self.isMakingNewObservation) {
        // insert new standalone observation into realm
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [realm addObject:self.standaloneObservation];
        [realm commitWriteTransaction];
    } else {
        // merge observation with standalone editing copy
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        // use addOrUpdateObject: instead of createOrUpdateInRealm: because
        // we want to allow users to delete photos and clear records
        [realm addOrUpdateObject:self.standaloneObservation];
        [realm commitWriteTransaction];
        
        // time to make deleted records for our stuff
        // would be nice to make this an inherited or protocol method
        for (id <Uploadable> recordToDelete in self.recordsToDelete) {
            if ([recordToDelete timeSynced]) {
                // has been synced, need to do a synced delete
                [[recordToDelete class] syncedDelete:recordToDelete];
            } else {
                // hasn't been synced, can be safely locally deleted
                [[recordToDelete class] deleteWithoutSync:recordToDelete];
            }
        }
    }
    
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:^{
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
    }];
}

#pragma mark - Taxa Search

- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxon chosenViaVision:(BOOL)visionFlag {
    if ([taxon isKindOfClass:[ExploreTaxon class]]) {
        taxon = [ExploreTaxonRealm objectForPrimaryKey:@(taxon.taxonId)];
    }
    
    if ([taxon isKindOfClass:[ExploreTaxonRealm class]]) {
        self.standaloneObservation.taxon = (ExploreTaxonRealm *)taxon;
        self.standaloneObservation.timeUpdatedLocally = [NSDate date];
        self.standaloneObservation.ownersIdentificationFromVision = visionFlag;
    }
    
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
    self.standaloneObservation.taxon = nil;
    self.standaloneObservation.speciesGuess = speciesGuess;
    self.standaloneObservation.timeUpdatedLocally = [NSDate date];
    
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
    
    self.shouldContinueUpdatingLocation = NO;
    [self stopUpdatingLocation];
    
    if (location.latitude.integerValue == 0 && location.longitude.integerValue == 0) {
        // nothing happens on null island
        self.standaloneObservation.latitude = kCLLocationCoordinate2DInvalid.latitude;
        self.standaloneObservation.longitude = kCLLocationCoordinate2DInvalid.longitude;
        self.standaloneObservation.privatePositionalAccuracy = -1;
        self.standaloneObservation.placeGuess = nil;
        return;
    }
    
    self.standaloneObservation.latitude = location.latitude.doubleValue;
    self.standaloneObservation.longitude = location.longitude.doubleValue;
    self.standaloneObservation.privatePositionalAccuracy = location.accuracy.doubleValue;
    self.standaloneObservation.placeGuess = nil;
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationLocationChanged
                     withProperties:@{
                         @"Via": [self analyticsVia],
                     }];
    
    [self.navigationController popToViewController:self animated:YES];
    
    [self reverseGeocodeCoordinatesForObservation:self.standaloneObservation];
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
                return CLLocationCoordinate2DIsValid(self.standaloneObservation.location) ? 66 : 44;
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
            return [self mediaCellInTableView:tableView];
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
                if (self.standaloneObservation.speciesGuess && !self.standaloneObservation.taxon) {
                    search.query = self.standaloneObservation.speciesGuess;
                }
                search.allowsFreeTextSelection = YES;
                
                if (self.standaloneObservation.observationPhotos.count > 0) {
                    ExploreObservationPhotoRealm *op = [self.standaloneObservation.sortedObservationPhotos firstObject];
                    NSString *imgKey = [op photoKey];
                    if (imgKey) {
                        UIImage *image = [[ImageStore sharedImageStore] find:imgKey forSize:ImageStoreSmallSize];
                        search.imageToClassify = image;
                    }
                    if (!search.imageToClassify) {
                        // if we couldn't find it in the imagestore,
                        // try to load it from the afnetworking caches
                        NSURLRequest *request = [NSURLRequest requestWithURL:op.smallPhotoUrl];
                        UIImage *image = [[[UIImageView sharedImageDownloader] imageCache] imageforRequest:request
                                                                                  withAdditionalIdentifier:nil];;
                        if (image) {
                            search.imageToClassify = image;
                        } else if (self.standaloneObservation.observationId != 0) {
                            // if we _still_ can't find an image, and the obs has been uploaded
                            // to inat, try classifying the observation by id
                            search.observationToClassify = self.standaloneObservation;
                        }
                    }
                    
                    if (search.imageToClassify) {
                        if (CLLocationCoordinate2DIsValid(self.standaloneObservation.visibleLocation)) {
                            search.coordinate = self.standaloneObservation.visibleLocation;
                        }
                        if (self.standaloneObservation.timeObserved) {
                            search.observedOn = self.standaloneObservation.timeObserved;
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
                                                 selectedDate:self.standaloneObservation.timeObserved ?: [NSDate date]
                                                    doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                    
                    NSDate *date = (NSDate *)selectedDate;
                    
                    if ([date timeIntervalSinceDate:self.standaloneObservation.timeObserved] == 0) {
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
                    strongSelf.standaloneObservation.timeObserved = date;
                    strongSelf.standaloneObservation.timeUpdatedLocally = [NSDate date];
                    
                    [strongSelf.tableView beginUpdates];
                    [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                withRowAnimation:UITableViewRowAnimationNone];
                    [strongSelf.tableView endUpdates];
                    
                } cancelBlock:nil
                                                       origin:cell] showActionSheetPicker];
            } else if (indexPath.item == 2) {
                // show location chooser
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                EditLocationViewController *map = [storyboard instantiateViewControllerWithIdentifier:@"EditLocationViewController"];
                map.delegate = self;
                
                if (CLLocationCoordinate2DIsValid(self.standaloneObservation.location)) {
                    INatLocation *loc = [[INatLocation alloc] initWithLatitude:@(self.standaloneObservation.latitude)
                                                                     longitude:@(self.standaloneObservation.longitude)
                                                                      accuracy:@(self.standaloneObservation.positionalAccuracy)];
                    // TODO: support positioning method?
                    //loc.positioningMethod = self.observation.positioningMethod;
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
                
                NSInteger initialSelection = [geoprivacyOptions indexOfObject:self.standaloneObservation.geoprivacy];
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
                    
                    strongSelf.standaloneObservation.geoprivacy = newValue;
                    strongSelf.standaloneObservation.timeUpdatedLocally = [NSDate date];
                    
                    [[Analytics sharedClient] event:kAnalyticsEventObservationGeoprivacyChanged
                                     withProperties:@{ @"Via": [self analyticsVia],
                                                       @"New Value": newValue}];
                    
                    [strongSelf.tableView beginUpdates];
                    [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                withRowAnimation:UITableViewRowAnimationNone];
                    [strongSelf.tableView endUpdates];
                    
                } cancelBlock:nil
                                                         origin:cell] showActionSheetPicker];
            } else if (indexPath.item == 4) {
                // captive/cultivated
                
                NSArray *captiveOptions = @[
                    NSLocalizedString(@"No", @"negative response to binary choice, yes or no"),
                    NSLocalizedString(@"Yes", @"positive response to binary choice, yes or no"),
                ];
                NSInteger selectedIndex = self.standaloneObservation.isCaptive ? 1 : 0;
                
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
                    
                    strongSelf.standaloneObservation.captive = (selectedIndex == 1) ? true : false;
                    strongSelf.standaloneObservation.timeUpdatedLocally = [NSDate date];
                    
                    [strongSelf.tableView beginUpdates];
                    [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                withRowAnimation:UITableViewRowAnimationNone];
                    [strongSelf.tableView endUpdates];
                    
                } cancelBlock:nil
                                                         origin:cell] showActionSheetPicker];
            } else if (indexPath.item == 5) {
                INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
                if (appDelegate.loginController.isLoggedIn) {
                    ProjectObservationsViewController *projectsVC = [[ProjectObservationsViewController alloc] initWithNibName:nil bundle:nil];
                    projectsVC.observation = self.standaloneObservation;
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

- (UITableViewCell *)mediaCellInTableView:(UITableView *)tableView {
    MediaScrollViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"media"];
    
    cell.media = self.standaloneObservation.observationMedia;
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
    
    RLMResults *results = [ExploreTaxonRealm objectsWhere:@"taxonId == %ld", (long)self.standaloneObservation.taxonRecordID];
    
    if (results.count == 1) {
        ExploreTaxonRealm *etr = [results firstObject];
        
        cell.taxonNameLabel.text = etr.displayFirstName;
        if (etr.displayFirstNameIsItalicized) {
            cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:cell.taxonNameLabel.font.pointSize];
        }
        
        cell.taxonSecondaryNameLabel.text = etr.displaySecondName;
        if (etr.displaySecondNameIsItalicized) {
            cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:cell.taxonSecondaryNameLabel.font.pointSize];
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
        
        if (self.standaloneObservation.speciesGuess) {
            cell.taxonNameLabel.text = self.standaloneObservation.speciesGuess;
        } else {
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            cell.taxonNameLabel.textColor = [UIColor colorWithHexString:@"#777777"];
            cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
            cell.taxonSecondaryNameLabel.textColor = [UIColor colorWithHexString:@"#777777"];
            cell.taxonNameLabel.text = NSLocalizedString(@"What did you see?", @"unknown taxon title");
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kINatSuggestionsPrefKey] &&
                self.standaloneObservation.sortedObservationPhotos.count > 0) {
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
    
    if (self.standaloneObservation.inatDescription && self.standaloneObservation.inatDescription.length > 0) {
        cell.textView.text = self.standaloneObservation.inatDescription;
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
    
    cell.titleLabel.text = [self.standaloneObservation observedOnShortString];
    FAKIcon *calendar = [FAKINaturalist iosCalendarOutlineIconWithSize:44];
    [calendar addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
    cell.cellImageView.image = [calendar imageWithSize:CGSizeMake(44, 44)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)locationCellInTableView:(UITableView *)tableView {
    
    static NSNumberFormatter *coordinateFormatter = nil;
    if (!coordinateFormatter) {
        coordinateFormatter = [[NSNumberFormatter alloc] init];
        coordinateFormatter.locale = [NSLocale currentLocale];
        coordinateFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        coordinateFormatter.maximumFractionDigits = 3;
    }
    
    DisclosureCell *cell;
    
    CLLocationCoordinate2D coords = kCLLocationCoordinate2DInvalid;
    
    if (CLLocationCoordinate2DIsValid(self.standaloneObservation.location)) {
        coords = self.standaloneObservation.location;
    }
    
    if (CLLocationCoordinate2DIsValid(coords)) {
        SubtitleDisclosureCell *subtitleCell = [tableView dequeueReusableCellWithIdentifier:@"subtitleDisclosure"];
        cell = subtitleCell;
        
        NSString *positionalAccuracy = nil;
        if (self.standaloneObservation.positionalAccuracy) {
            NSString *accuracyBaseString = NSLocalizedString(@"%ld m", "format string for showing positional accuracy in meters");
            positionalAccuracy = [NSString stringWithFormat:accuracyBaseString,
                                  (long)self.standaloneObservation.positionalAccuracy];
        } else {
            positionalAccuracy = NSLocalizedString(@"???", @"positional accuracy when we don't know");
        }
        NSString *coordinateBaseString = NSLocalizedString(@"Lat: %1$@, Long: %2$@, Acc: %3$@", @"format string for showing latitude, longitude, & positional accuracy");
        NSString *subtitleString = [NSString stringWithFormat:coordinateBaseString,
                                    [coordinateFormatter stringFromNumber:[NSNumber numberWithDouble:coords.latitude]],
                                    [coordinateFormatter stringFromNumber:[NSNumber numberWithDouble:coords.longitude]],
                                    positionalAccuracy];
        subtitleCell.subtitleLabel.text = subtitleString;
        
        if (self.standaloneObservation.placeGuess && self.standaloneObservation.placeGuess.length > 0) {
            subtitleCell.titleLabel.text = self.standaloneObservation.placeGuess;
        } else {
            subtitleCell.titleLabel.text = NSLocalizedString(@"Unable to find location name", @"place guess when we have lat/lng but it's not geocoded");
            // only try to persistently, passively geocode a placeguess if this is a new observation
            if (self.isMakingNewObservation) {
                [self reverseGeocodeCoordinatesForObservation:self.standaloneObservation];
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
    cell.secondaryLabel.text = self.standaloneObservation.geoprivacy;
    
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
    cell.secondaryLabel.text = self.standaloneObservation.captive ? NSLocalizedString(@"Yes", nil) : NSLocalizedString(@"No", @"Generic negative response to a yes/no question");
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
    
    if (self.standaloneObservation.projectObservations.count > 0) {
        cell.secondaryLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.standaloneObservation.projectObservations.count];
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
    return nil;
}

#pragma mark - UITableViewCell title helpers

- (NSString *)geoPrivacyTitle {
    return NSLocalizedString(@"Geoprivacy", @"Geoprivacy button title");
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
