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

#import "ConfirmObservationViewController.h"
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
#import "PhotoScrollView.h"
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

typedef NS_ENUM(NSInteger, ConfirmObsSection) {
    ConfirmObsSectionPhotos = 0,
    ConfirmObsSectionIdentify,
    ConfirmObsSectionNotes,
};

@interface ConfirmObservationViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, EditLocationViewControllerDelegate, PhotoScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QBImagePickerControllerDelegate, TaxaSearchViewControllerDelegate, ProjectChooserViewControllerDelegate>
@property UITableView *tableView;
@property UIButton *saveButton;
@property (readonly) NSString *notesPlaceholder;
@end

@implementation ConfirmObservationViewController

#pragma mark - uiviewcontroller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tv.translatesAutoresizingMaskIntoConstraints = NO;

        tv.dataSource = self;
        tv.delegate = self;
        
        // no separator inset
        if ([tv respondsToSelector:@selector(setLayoutMargins:)]) {
            tv.layoutMargins = UIEdgeInsetsZero;
        }
        
        [tv registerClass:[DisclosureCell class] forCellReuseIdentifier:@"disclosure"];
        [tv registerClass:[SubtitleDisclosureCell class] forCellReuseIdentifier:@"subtitleDisclosure"];
        [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"photos"];
        [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"switch"];
        [tv registerClass:[TextViewCell class] forCellReuseIdentifier:@"notes"];
        
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
        
        [button setTitle:NSLocalizedString(@"Save", @"Title for save new observation button")
                forState:UIControlStateNormal];
        [button addTarget:self action:@selector(saved:) forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:self.saveButton];
    
    NSDictionary *views = @{
                            @"tv": self.tableView,
                            @"save": self.saveButton,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[tv]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[save]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-0-[save(==44)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    self.title = NSLocalizedString(@"Details", @"Title for confirm new observation details view");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.tintColor = [UIColor inatTint];
    [self.tableView reloadData];
}

- (void)saved:(UIButton *)button {
    NSError *error;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        // TODO: log it at least, also notify the user
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:self.notesPlaceholder]) {
        textView.textColor = [UIColor blackColor];
        textView.text = @"";
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.observation.inatDescription = textView.text;
    
    if (textView.text.length == 0) {
        textView.textColor = [UIColor colorWithHexString:@"#AAAAAA"];
        textView.text = self.notesPlaceholder;
    }
}

#pragma mark - textview helper
- (NSString *)notesPlaceholder {
    return NSLocalizedString(@"Notes...", @"Placeholder for observation notes when making a new observation.");
}

#pragma mark - PhotoScrollViewDelegate

- (void)photoScrollView:(PhotoScrollView *)psv setDefaultIndex:(NSInteger)idx {
    ObservationPhoto *originalDefault = self.observation.sortedObservationPhotos[0];
    ObservationPhoto *newDefault = self.observation.sortedObservationPhotos[idx];
    originalDefault.position = @(newDefault.position.integerValue);
    newDefault.position = @(0);
    
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionPhotos] ]
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (void)photoScrollView:(PhotoScrollView *)psv deletedIndex:(NSInteger)idx {
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
    
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:ConfirmObsSectionPhotos] ]
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (void)photoScrollViewAddPressed:(PhotoScrollView *)psv {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self pushCamera];
    } else {
        [self pushLibrary];
    }
}

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

#pragma mark UIImagePickerControllerDelegate methods

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


#pragma mark - geocoding helper
- (void)reverseGeocodeCoordinatesForObservation:(Observation *)obs {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:obs.latitude.floatValue
                                                 longitude:obs.longitude.floatValue];
    
    static CLGeocoder *geoCoder;
    if (!geoCoder)
        geoCoder = [[CLGeocoder alloc] init];
    
    [geoCoder cancelGeocode];       // cancel anything in flight
    
    [geoCoder reverseGeocodeLocation:loc
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
    self.observation.idPlease = [NSNumber numberWithBool:switcher.isOn];
}

- (void)captiveChanged:(UISwitch *)switcher {
    self.observation.captive = [NSNumber numberWithBool:switcher.isOn];
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
    
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - EditLocation 

- (void)editLocationViewControllerDidSave:(EditLocationViewController *)controller location:(INatLocation *)location {
    
    if (location.latitude.integerValue == 0 && location.longitude.integerValue == 0) {
        // nothing happens on null island
        return;
    }
    
    self.observation.latitude = location.latitude;
    self.observation.longitude = location.longitude;
    self.observation.positionalAccuracy = location.accuracy;
    self.observation.positioningMethod = location.positioningMethod;
    
    [self.navigationController popToViewController:self animated:YES];

    [self reverseGeocodeCoordinatesForObservation:self.observation];
}

#pragma mark - table view delegate / datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
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
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ConfirmObsSectionPhotos) {
        return 108;
    } else if (indexPath.section == ConfirmObsSectionNotes && indexPath.item == 0) {
        return 66;
    } else if (indexPath.section == ConfirmObsSectionNotes && indexPath.item == 2) {
        if (self.observation.latitude && self.observation.longitude) {
            return 66;
        } else {
            return 44;
        }
    } else {
        return 44;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ConfirmObsSectionPhotos:
            return 0;
            break;
        case ConfirmObsSectionIdentify:
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
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        // no separator inset
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    cell.separatorInset = UIEdgeInsetsZero;
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
        default:
            return [self illegalCellForIndexPath:indexPath];
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
                                                        
                                                        __strong typeof(weakSelf) strongSelf = self;
                                                        strongSelf.observation.localObservedOn = selectedDate;
                                                        strongSelf.observation.observedOnString = [Observation.jsDateFormatter stringFromDate:selectedDate];
                                                        
                                                        [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                    withRowAnimation:UITableViewRowAnimationFade];
                                                        
                                                    } cancelBlock:nil
                                                       origin:self.view] showActionSheetPicker];
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

                NSInteger selectedIndex = [geoprivacyOptions indexOfObject:self.observation.geoprivacy];
                if (selectedIndex == NSNotFound) {
                    selectedIndex = 0;
                }
                
                __weak typeof(self) weakSelf = self;
                [[[ActionSheetStringPicker alloc] initWithTitle:NSLocalizedString(@"Select Privacy", @"title for geoprivacy selector")
                                                           rows:presentableGeoPrivacyOptions
                                               initialSelection:selectedIndex
                                                      doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                          
                                                          __strong typeof(weakSelf) strongSelf = weakSelf;
                                                          
                                                          strongSelf.observation.geoprivacy = geoprivacyOptions[selectedIndex];
                                                          
                                                          [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                      withRowAnimation:UITableViewRowAnimationFade];

                                                      } cancelBlock:nil
                                                         origin:self.view] showActionSheetPicker];
            } else if (indexPath.item == 5) {
                
                ProjectObservationsViewController *projectsVC = [[ProjectObservationsViewController alloc] initWithNibName:nil bundle:nil];
                projectsVC.observation = self.observation;
                
                NSMutableArray *projects = [NSMutableArray array];
                [[ProjectUser all] enumerateObjectsUsingBlock:^(ProjectUser *pu, NSUInteger idx, BOOL * _Nonnull stop) {
                    [projects addObject:pu.project];
                }];
                
                projectsVC.joinedProjects = [NSArray arrayWithArray:projects];
                
                [self.navigationController pushViewController:projectsVC animated:YES];
            
            } else {
                // do nothing
            }
            break;
        default:
            // do nothing
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ConfirmObsSectionPhotos:
            return nil;
            break;
        case ConfirmObsSectionIdentify:
            return NSLocalizedString(@"What did you see?", @"title for identification section of new obs confirm screen.");
            break;
        case ConfirmObsSectionNotes:
            return nil;
            break;
        default:
            return nil;
            break;
    }
}

#pragma mark - table view cell helpers

- (UITableViewCell *)photoCellInTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"photos"];
    
    PhotoScrollView *photoScrollView;
    if (![cell viewWithTag:0x999]) {
        photoScrollView = [[PhotoScrollView alloc] initWithFrame:cell.contentView.bounds];
        photoScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        photoScrollView.tag = 0x999;
        
        photoScrollView.delegate = self;
        
        [cell.contentView addSubview:photoScrollView];
    } else {
        photoScrollView = (PhotoScrollView *)[cell viewWithTag:0x999];
    }
    
    photoScrollView.photos = self.observation.sortedObservationPhotos;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (UITableViewCell *)speciesCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    Taxon *taxon = self.observation.taxon;
    if (taxon) {
        cell.titleLabel.text = taxon.defaultName;
        if ([taxon.isIconic boolValue]) {
            cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        } else if (taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = taxon.taxonPhotos.firstObject;
            [cell.cellImageView sd_setImageWithURL:[NSURL URLWithString:tp.thumbURL]];
        } else {
            cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:nil];
        }
    } else {
        FAKIcon *question = [FAKINaturalist unknownSpeciesIconWithSize:44];
        
        [question addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
        cell.cellImageView.image = [question imageWithSize:CGSizeMake(44, 44)];
        cell.titleLabel.text = NSLocalizedString(@"Something...", nil);
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)helpIdCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = @"Help Me ID this Species";
    FAKIcon *bouy = [FAKINaturalist lifebuoyIconWithSize:44];
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
    FAKIcon *calendar = [FAKIonIcons iosCalendarOutlineIconWithSize:44];
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
    
    cell.titleLabel.text = NSLocalizedString(@"Geo Privacy", @"Geoprivacy button title");
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
    
    cell.titleLabel.text = NSLocalizedString(@"Is it captive or cultivated?", @"Captive / cultivated button title.");
    
    FAKIcon *cage = [FAKINaturalist captiveIconWithSize:44];
    [cage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
    cell.cellImageView.image = [cage imageWithSize:CGSizeMake(44, 44)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switcher addTarget:self action:@selector(captiveChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switcher;
    
    return cell;
}


- (UITableViewCell *)projectsCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = NSLocalizedString(@"Projects", @"choose projects button title.");
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

- (UITableViewCell *)illegalCellForIndexPath:(NSIndexPath *)ip {
    NSLog(@"indexpath is %@", ip);
    NSAssert(NO, @"shouldn't reach here");
}




@end
