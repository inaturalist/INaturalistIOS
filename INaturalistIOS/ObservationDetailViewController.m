//
//  INObservationFormViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <QBImagePickerController/QBImagePickerController.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <MHVideoPhotoGallery/MHTransitionDismissMHGallery.h>

#import "ObservationDetailViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import "ObservationField.h"
#import "ObservationFieldValue.h"
#import "ObservationPageViewController.h"
#import "Project.h"
#import "ProjectObservation.h"
#import "ProjectObservationField.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "EditLocationViewController.h"
#import "ActionSheetStringPicker.h"
#import "ActionSheetDatePicker.h"
#import "ObservationActivityViewController.h"
#import "UIImageView+WebCache.h"
#import "UIColor+INaturalist.h"
#import "TKCoverflowCoverView+INaturalist.h"
#import "TaxonDetailViewController.h"
#import "Analytics.h"
#import "ObsCameraOverlay.h"
#import "ConfirmPhotoViewController.h"
#import "Observation+AddAssets.h"

static const int LocationActionSheetTag = 1;
static const int DeleteActionSheetTag = 3;
static const int ViewActionSheetTag = 4;
static const int GeoprivacyActionSheetTag = 5;
static const int TaxonTableViewSection = 0;
static const int NotesTableViewSection = 1;
static const int LocationTableViewSection = 2;
static const int ObservedOnTableViewSection = 3;
static const int MoreSection = 4;
static const int ProjectsSection = 5;
NSString *const ObservationFieldValueDefaultCell = @"ObservationFieldValueDefaultCell";
NSString *const ObservationFieldValueStaticCell = @"ObservationFieldValueStaticCell";
NSString *const ObservationFieldValueSwitchCell = @"ObservationFieldValueSwitchCell";

@implementation OFVTaxaSearchControllerDelegate
@synthesize controller = _controller;
@synthesize indexPath = _indexPath;

- (id)initWithController:(ObservationDetailViewController *)controller
{
    self = [super init];
    if (self) {
        self.controller = controller;
    }
    return self;
}

- (void)taxaSearchViewControllerChoseTaxon:(Taxon *)taxon
{
    [self.controller dismissViewControllerAnimated:YES completion:nil];
    ObservationFieldValue *ofv = [self.controller observationFieldValueForIndexPath:self.indexPath];
    [self.controller.ofvCells removeObjectForKey:ofv.observationField.name];
    ofv.value = [taxon.recordID stringValue];
    [self.controller.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:self.indexPath]
                                     withRowAnimation:UITableViewRowAnimationNone];
}
@end

@interface ObservationDetailViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate,QBImagePickerControllerDelegate,MHGalleryDelegate>
@property UIBarButtonItem *bigSave;
@end

@implementation ObservationDetailViewController

@synthesize observedAtLabel;
@synthesize latitudeLabel = _latitudeLabel;
@synthesize longitudeLabel = _longitudeLabel;
@synthesize positionalAccuracyLabel;
@synthesize placeGuessField = _placeGuessField;
@synthesize idPleaseSwitch = _idPleaseSwitch;
@synthesize geoprivacyCell = _geoprivacyCell;
@synthesize keyboardToolbar = _keyboardToolbar;
@synthesize saveButton = _saveButton;
@synthesize deleteButton = _deleteButton;
@synthesize viewButton = _viewButton;
@synthesize speciesGuessTextField = _speciesGuessTextField;
@synthesize descriptionTextView;
@synthesize delegate = _delegate;
@synthesize observation = _observation;
@synthesize observationPhotos = _observationPhotos;
@synthesize observationFieldValues = _observationFieldValues;
@synthesize coverflowView = _coverflowView;
@synthesize locationManager = _locationManager;
@synthesize locationTimer = _locationTimer;
@synthesize geocoder = _geocoder;
@synthesize popOver = _popOver;
@synthesize currentActionSheet = _currentActionSheet;
@synthesize locationUpdatesOn = _locationUpdatesOn;
@synthesize observationWasNew = _observationWasNew;
@synthesize lastImageReferenceURL = _lastImageReferenceURL;
@synthesize ofvCells = _ofvCells;
@synthesize ofvTaxaSearchControllerDelegate = _ofvTaxaSearchControllerDelegate;
@synthesize taxonID = _taxonID;

- (void)observationToUI
{
    if (!self.observation) return;
    [self.speciesGuessTextField setText:self.observation.speciesGuess];
    [self.observedAtLabel setText:self.observation.observedOnPrettyString];
    [self.placeGuessField setText:self.observation.placeGuess];
    NSNumber *lat = self.observation.visibleLatitude;
    NSNumber *lon = self.observation.visibleLongitude;
    
    if (lat) {
        [self.latitudeLabel setText:lat.description];
    } else {
        self.latitudeLabel.text = nil;
    }
    if (lon) {
        [self.longitudeLabel setText:lon.description];
    } else {
        self.longitudeLabel.text = nil;
    }
    
    if (self.observation.positionalAccuracy) {
        [positionalAccuracyLabel setText:self.observation.positionalAccuracy.description];
    } else {
        self.positionalAccuracyLabel.text = nil;
    }
    [descriptionTextView setText:self.observation.inatDescription];
    
    UITableViewCell *speciesCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIImageView *img = (UIImageView *)[speciesCell viewWithTag:1];
    UIButton *rightButton = (UIButton *)[speciesCell viewWithTag:3];
    img.layer.cornerRadius = 5.0f;
    img.clipsToBounds = YES;

    [img sd_cancelCurrentImageLoad];
    UIImage *iconicTaxonImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.observation.iconicTaxonName];
    img.image = iconicTaxonImage;
    if (self.observation.taxon) {
        if (self.observation.taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = (TaxonPhoto *)self.observation.taxon.taxonPhotos.firstObject;
            [img sd_setImageWithURL:[NSURL URLWithString:tp.squareURL]
                   placeholderImage:iconicTaxonImage];
        }
        self.speciesGuessTextField.enabled = NO;
        if (self.speciesGuessTextField.text.length == 0 && self.observation.speciesGuess.length == 0) {
            self.speciesGuessTextField.text = self.observation.taxon.defaultName;
        }
        rightButton.imageView.image = [UIImage imageNamed:@"298-circlex.png"];
        self.speciesGuessTextField.textColor = [Taxon iconicTaxonColor:self.observation.taxon.iconicTaxonName];
    } else {
        rightButton.imageView.image = [UIImage imageNamed:@"06-magnify.png"];
        self.speciesGuessTextField.enabled = YES;
        self.speciesGuessTextField.textColor = [UIColor blackColor];
    }
    
    if (self.observation.idPlease) {
        [self.idPleaseSwitch setOn:self.observation.idPlease.boolValue];
    }
    if (self.observation.geoprivacy) {
        self.geoprivacyCell.detailTextLabel.text = self.observation.geoprivacy;
    }
    
    // Note: populating dynamic table cell values probably occurs in tableView:cellForRowAtIndexPath:ß
}

- (void)uiToObservation
{
    if (!self.speciesGuessTextField) return;
    
    // if observation text is nil, and textfield/view text is @"", they're equivalent and don't need saving.
    if (![self.observation.speciesGuess isEqualToString:self.speciesGuessTextField.text] &&
        !(self.observation.speciesGuess == nil && [self.speciesGuessTextField.text isEqualToString:@""])) {
        [self.observation setSpeciesGuess:[self.speciesGuessTextField text]];
    }
    if (![self.observation.inatDescription isEqualToString:self.descriptionTextView.text] &&
        !(self.observation.inatDescription == nil && [self.descriptionTextView.text isEqualToString:@""])) {
        [self.observation setInatDescription:[descriptionTextView text]];
    }
    if (![self.observation.placeGuess isEqualToString:self.placeGuessField.text] &&
        !(self.observation.placeGuess == nil && [self.placeGuessField.text isEqualToString:@""])) {
        [self.observation setPlaceGuess:[self.placeGuessField text]];
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setLocale:[NSLocale systemLocale]];
    NSNumber *newLat = [numberFormatter numberFromString:self.latitudeLabel.text];
    NSNumber *newLon = [numberFormatter numberFromString:self.longitudeLabel.text];
    NSNumber *newAcc = [numberFormatter numberFromString:self.positionalAccuracyLabel.text];
    if (newLat && ![self.observation.visibleLatitude isEqualToNumber:newLat]) {
        self.observation.latitude = newLat;
        self.observation.privateLatitude = nil;
    }
    if (newLon && ![self.observation.visibleLongitude isEqualToNumber:newLon]) {
        self.observation.longitude = newLon;
        self.observation.privateLongitude = nil;
    }
    if (newAcc && ![self.observation.positionalAccuracy isEqualToNumber:newAcc]) {
        self.observation.positionalAccuracy = newAcc;
    }
    self.observation.idPlease = [NSNumber numberWithBool:self.idPleaseSwitch.on];
    
    for (NSString *key in self.ofvCells) {
        UITableViewCell *cell = [self.ofvCells objectForKey:key];
        NSUInteger ofvIndex = [self.observationFieldValues indexOfObjectPassingTest:^BOOL(ObservationFieldValue *obj, NSUInteger idx, BOOL *stop) {
            return [obj.observationField.name isEqualToString:key];
        }];
        if (ofvIndex == NSNotFound) {
            continue;
        }
        ObservationFieldValue *ofv = [self.observationFieldValues objectAtIndex:ofvIndex];
        if ([cell.reuseIdentifier isEqualToString:ObservationFieldValueSwitchCell]) {
            DCRoundSwitch *roundSwitch = (DCRoundSwitch *)[cell viewWithTag:2];
            if (roundSwitch.on) {
                ofv.value = [ofv.observationField.allowedValuesArray firstObject];
            } else {
                ofv.value = [ofv.observationField.allowedValuesArray lastObject];
            }
        } else if ([ofv.observationField.datatype isEqualToString:@"taxon"]) {
            Taxon *t = [Taxon objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID = %@", ofv.value]];
            UILabel *label = (UILabel *)[cell viewWithTag:2];
            if ([label.text isEqualToString:@"unknown"]) {
                ofv.value = nil;
            
            // This is messed up, but the ofv value is usually set when the UI is updated,
            // and I haven't found a good way to store the taxon ID in the UI while still
            // displaying the name, so we do a check here to make sure they match and if
            // not try to find the taxon by the name in the label.
            } else if (t == nil || ![t.name isEqualToString:label.text]) {
                t = [Taxon objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID = %@", label.text]];
                if (t) {
                    ofv.value = [t.recordID stringValue];
                }
            }
        } else {
            UITextField *textField = (UITextField *)[cell viewWithTag:2];
            ofv.value = textField.text;
        }
    }
}

- (void)initUI
{
    UINavigationItem *navItem;
    if ([self.parentViewController isKindOfClass:ObservationPageViewController.class]) {
        self.parentViewController.navigationItem.leftBarButtonItem = self.navigationItem.leftBarButtonItem;
        self.parentViewController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
        navItem = self.parentViewController.navigationItem;
    } else {
        navItem = self.navigationItem;
    }
    
    // first access of self.observation in -initUI
    // be defensive about self.observation being able to be faulted
    @try {
        navItem.title = [self.observation isNew] ? NSLocalizedString(@"Add observation",nil) : NSLocalizedString(@"Edit observation",nil);
    } @catch (NSException *exception) {
        if ([exception.name isEqualToString:NSObjectInaccessibleException]) {
            // if self.observation has been deleted or is otherwise inaccessible, pop to observations
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
    }

    if (!self.saveButton) {
        self.saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",nil)
                                                           style:UIBarButtonItemStyleDone 
                                                          target:self
                                                          action:@selector(clickedSave)];
        [self.saveButton setWidth:100.0];
        [self.saveButton setTintColor:[UIColor inatTint]];
    }
    
    if (!self.deleteButton) {
        self.deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                          target:self
                                                          action:@selector(clickedDelete)];
    }
    
    if (!self.viewButton) {
        self.viewButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                        target:self
                                                                        action:@selector(clickedView)];
        if (!self.observation.syncedAt) {
            [self.viewButton setEnabled:NO];
        }
    }
	
	if (!self.activityButton) {
		self.activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
		self.activityButton.frame = CGRectMake(0, 0, 50, 50);
		self.activityButton.titleEdgeInsets = UIEdgeInsetsMake(-5, 1, 0, 0);
		self.activityButton.titleLabel.font = [UIFont systemFontOfSize:11.0];
        [self.activityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[self.activityButton addTarget:self action:@selector(clickedActivity:) forControlEvents:UIControlEventTouchUpInside];
	}
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.activityButton.frame];
    imageView.contentMode = UIViewContentModeCenter;
	if (self.observation.hasUnviewedActivity.boolValue) {
        imageView.image = [UIImage imageNamed:@"08-chat-red.png"];
	} else {
        imageView.image = [UIImage imageNamed:@"08-chat.png"];
	}
    [self.activityButton insertSubview:imageView atIndex:0];
	[self.activityButton setTitle:[NSString stringWithFormat:@"%ld", (long)self.observation.activityCount] forState:UIControlStateNormal];
	
	if (!self.activityBarButton) {
        self.activityBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.activityButton];
    }
    
    if (!self.observation.recordID) {
        [self.activityButton setHidden:YES];
    }
    
    UIButton *bigSaveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    bigSaveButton.frame = CGRectMake(0, 0, 150, 44);
    bigSaveButton.tintColor = [UIColor whiteColor];
    [bigSaveButton setTitle:@"SAVE" forState:UIControlStateNormal];
    bigSaveButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    bigSaveButton.titleLabel.font = [UIFont boldSystemFontOfSize:36];
    [bigSaveButton addTarget:self action:@selector(clickedSave) forControlEvents:UIControlEventTouchUpInside];
    
    self.bigSave = [[UIBarButtonItem alloc] initWithCustomView:bigSaveButton];
    self.bigSave.tintColor = [UIColor whiteColor];
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                             target:nil
                             action:nil];
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                              target:nil
                              action:nil];
	fixed.width = self.activityButton.frame.size.width;
    
    UIViewController *tbvc = [self getToolbarViewController];
    if (self.shouldShowBigSaveButton) {
        [tbvc setToolbarItems:@[
                                flex,
                                self.bigSave,
                                flex
                                ]];
    } else {
        [tbvc setToolbarItems:[NSArray arrayWithObjects:
                               self.deleteButton,
                               flex,
                               fixed,
                               flex,
                               self.saveButton,
                               flex,
                               self.activityBarButton,
                               flex,
                               self.viewButton,
                               nil]
                     animated:NO];
    }
    [tbvc.navigationController setToolbarHidden:NO animated:YES];
    
    if (!self.keyboardToolbar) {
        self.keyboardToolbar = [[UIToolbar alloc] init];
        self.keyboardToolbar.barStyle = UIBarStyleBlackOpaque;
        [self.keyboardToolbar sizeToFit];
        UIBarButtonItem *prevButton = [[UIBarButtonItem alloc] 
                                        initWithTitle:NSLocalizedString(@"Prev", @"Previous")
                                        style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(focusOnPrevField)];
        UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] 
                                        initWithTitle:NSLocalizedString(@"Next",nil)
                                        style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(focusOnNextField)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] 
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                       target:self 
                                       action:@selector(keyboardDone)];
        [self.keyboardToolbar setItems:[NSArray arrayWithObjects:
                                        prevButton, 
                                        nextButton,
                                        flex, 
                                        doneButton, 
                                        nil]];
    }
    
    self.idPleaseSwitch.onText = NSLocalizedString(@"YES", nil);
    self.idPleaseSwitch.offText = NSLocalizedString(@"NO", nil);
    
    [self refreshCoverflowView];
    
    BOOL taxonIDSetExplicitly = self.taxonID && self.taxonID.length > 0;
    BOOL taxonFullyLoaded = self.observation && self.observation.taxon && self.observation.taxon.fullyLoaded;
    if (self.observation && (taxonIDSetExplicitly || !taxonFullyLoaded)) {
        NSUInteger taxonID = self.taxonID ? self.taxonID.intValue : self.observation.taxonID.intValue;
        NSPredicate *taxonByIDPredicate = [NSPredicate predicateWithFormat:@"recordID = %d", taxonID];
        Taxon *t = [Taxon objectWithPredicate:taxonByIDPredicate];
        if (t && t.fullyLoaded) {
            self.observation.taxon = t;
        } else if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
            NSString *url = [NSString stringWithFormat:@"%@/taxa/%ld.json", INatBaseURL, (long)taxonID];
            __weak typeof(self) weakSelf = self;
            
            RKObjectLoaderDidLoadObjectBlock taxonLoadedBlock = ^(id object) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                Taxon *loadedTaxon = (Taxon *)object;
                loadedTaxon.syncedAt = [NSDate date];
                
                // save into core data
                NSError *saveError = nil;
                [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                if (saveError) {
                    NSString *errMsg = [NSString stringWithFormat:@"Taxon Save Error: %@",
                                        saveError.localizedDescription];
                    [[Analytics sharedClient] debugLog:errMsg];
                    return;
                }
                
                Taxon *t = [Taxon objectWithPredicate:taxonByIDPredicate];
                strongSelf.observation.taxon = t;
                [strongSelf observationToUI];
            };
            
            [[RKObjectManager sharedManager] loadObjectsAtResourcePath:url
                                                            usingBlock:^(RKObjectLoader *loader) {
                                                                loader.objectMapping = [Taxon mapping];
                                                                loader.onDidLoadObject = taxonLoadedBlock;
                                                                // do nothing in the event of error
                                                            }];
        } else {
            NSLog(@"no network, ignore");
        }
    }
    [self observationToUI];
}

- (UIViewController *)getToolbarViewController
{
    if ([self.parentViewController isKindOfClass:ObservationPageViewController.class]) {
        return self.parentViewController;
    } else {
        return self;
    }
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // user prefs determine autocorrection/spellcheck behavior of the species guess field
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kINatAutocompleteNamesPrefKey]) {
        [self.speciesGuessTextField setAutocorrectionType:UITextAutocapitalizationTypeSentences];
        [self.speciesGuessTextField setSpellCheckingType:UITextSpellCheckingTypeDefault];
    } else {
        [self.speciesGuessTextField setAutocorrectionType:UITextAutocapitalizationTypeNone];
        [self.speciesGuessTextField setSpellCheckingType:UITextSpellCheckingTypeNo];
    }

    // Do any additional setup after loading the view from its nib.
    self.ofvTaxaSearchControllerDelegate = [[OFVTaxaSearchControllerDelegate alloc] initWithController:self];
    NSString *currentLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([currentLanguage isEqualToString:@"es"]) {
        NSDictionary *attrs = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:18] };
        self.navigationController.navigationBar.titleTextAttributes = attrs;
    }
    
    // add a black view to the top so pulling won't show whitespace
    CGRect frame = self.view.bounds;
    frame.origin.y = -frame.size.height;
    UIView * bgview = [[UIView alloc] initWithFrame:frame];
    bgview.backgroundColor = [UIColor blackColor];
    [self.view addSubview:bgview];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.observation) {
        [self reloadObservationFieldValues];
    }
    
    if (self.shouldShowBigSaveButton) {
        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
        self.navigationController.toolbar.barTintColor = [UIColor inatTint];
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    } else {
        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
        self.navigationController.toolbar.barTintColor = [UIColor whiteColor];
        self.navigationController.toolbar.tintColor = [UIColor inatTint];
    }

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {    
    [self initUI];
    [super viewDidAppear:animated];
    
    @try {
        if (self.observation.isNew &&
            (
             self.observation.latitude == nil || // observation has no coordinates yet
             self.locationUpdatesOn                              // location updates already started, but view trashed due to mem warning
             )) {
                [self startUpdatingLocation];
            }
    } @catch (NSException *exception) {
        if ([exception.name isEqualToString:NSObjectInaccessibleException]) {
            // for whatever reason (deleted via sync? deleted?) this observation
            // isn't valid. only safe thing to do is get out of the observation
            // detail view controller.
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            @throw exception;
        }
    }
    [self.getToolbarViewController.navigationController setToolbarHidden:NO
                                                                animated:animated];
    
    [self.coverflowView setCurrentCoverAtIndex:0 animated:YES];

    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateObservationDetail];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateObservationDetail];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
    [self setGeocoder:nil];
    [self setKeyboardToolbar:nil];
    self.saveButton = nil;
    self.deleteButton = nil;
    self.viewButton = nil;
    self.coverflowView = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (!self.observation.isDeleted && !self.didClickCancel) {
        [self save];
    }
    [self keyboardDone];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setSpeciesGuessTextField:nil];
    [self setObservedAtLabel:nil];
    [self setLatitudeLabel:nil];
    [self setLongitudeLabel:nil];
    [self setPositionalAccuracyLabel:nil];
    [self setDescriptionTextView:nil];
    [self setPlaceGuessField:nil];
    [self setIdPleaseSwitch:nil];
    [self setGeoprivacyCell:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark UITextFieldDelegate methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [textField setInputAccessoryView:self.keyboardToolbar];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.speciesGuessTextField) {
        [self clickedSpeciesButton:nil];    
    }
    [textField resignFirstResponder];
    return YES;
}


#pragma mark UITextViewDelegate methods
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [textView setInputAccessoryView:self.keyboardToolbar];
    return YES;
}

#pragma mark UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
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
            [strongSelf addPhoto:op];
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

#pragma mark TKCoverflowViewDelegate methods

- (void)refreshCoverflowView
{
    [self.tableView reloadData];
    [self.coverflowView reloadData];
    
    [self.coverflowView setNeedsDisplay];
    [self.coverflowView setNeedsLayout];
}

- (NSInteger)numberOfCoversInCoverflowView:(TKCoverflowView *)coverflowView {
    return self.observationPhotos.count;
}

- (TKCoverflowCoverView *)coverflowView:(TKCoverflowView *)coverflowView coverForIndex:(NSInteger)index {
    TKCoverflowCoverView *cover = [coverflowView dequeueReusableCoverView];
    
    if (!cover) {
        cover = [[TKCoverflowCoverView alloc] initWithFrame:CGRectMake(0, 0, coverflowView.coverSize.width, coverflowView.coverSize.height)
                                                 reflection:YES];
        cover.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }

    ObservationPhoto *op = [self.observationPhotos objectAtIndex:index];

	if (op.photoKey == nil) {
        TKCoverflowCoverView *boundCover = cover;
        
        [cover.imageView sd_setImageWithURL:[NSURL URLWithString:op.mediumURL ?: op.smallURL]
                           placeholderImage:[UIImage imageNamed:@"121-landscape.png"]
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                      if (error) {
                                          boundCover.image = [UIImage imageNamed:@"184-warning.png"];
                                      }
                                  }];
	} else {
		UIImage *img = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSmallSize];
		if (!img) img = [[ImageStore sharedImageStore] find:op.photoKey];
		if (img) cover.image = img;
	}
    return cover;
}

- (void)coverflowView:(TKCoverflowView *)coverflowView coverAtIndexWasTappedInFront:(NSInteger)index tapCount:(NSInteger)tapCount {
    ObservationPhoto *op = [self.observationPhotos objectAtIndex:index];
    if (!op) return;
    
    NSArray *galleryData = [self.observationPhotos bk_map:^id(ObservationPhoto *op) {
        return [MHGalleryItem itemWithURL:op.mediumPhotoUrl.absoluteString
                              galleryType:MHGalleryTypeImage];
    }];
    
    MHUICustomization *customization = [[MHUICustomization alloc] init];
    customization.showOverView = NO;
    customization.showMHShareViewInsteadOfActivityViewController = NO;
    customization.hideShare = NO;
    customization.useCustomBackButtonImageOnImageViewer = NO;
    
    MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarShown];
    gallery.galleryItems = galleryData;
    gallery.presentationIndex = 0;
    gallery.UICustomization = customization;
    
    gallery.galleryDelegate = self;
    
    __weak MHGalleryController *blockGallery = gallery;
    
    gallery.finishedCallback = ^(NSUInteger currentIndex,UIImage *image,MHTransitionDismissMHGallery *interactiveTransition,MHGalleryViewMode viewMode){
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockGallery dismissViewControllerAnimated:YES completion:nil];
        });
    };
    
    [self presentMHGalleryController:gallery animated:YES completion:^{
        // add a delete button
        NSMutableArray *toolbarItems = [gallery.imageViewerViewController.toolbar.items mutableCopy];
        [toolbarItems removeLastObject];
        [toolbarItems addObject:[[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                handler:^(id sender) {
                                                                                    [blockGallery dismissViewControllerAnimated:YES
                                                                                                               dismissImageView:nil
                                                                                                                     completion:nil];
                                                                                    ObservationPhoto *op = self.observationPhotos[blockGallery.presentationIndex];
                                                                                    [self.observationPhotos removeObject:op];
                                                                                    [op deleteEntity];
                                                                                    [self refreshCoverflowView];
                                                                                }]];
        gallery.imageViewerViewController.toolbar.items = toolbarItems;
    }];
}

// need to re-add the delete button each time the user goes forward or backward
- (void)galleryController:(MHGalleryController *)galleryController didShowIndex:(NSInteger)index {
    __weak MHGalleryController *blockGallery = galleryController;

    NSMutableArray *toolbarItems = [galleryController.imageViewerViewController.toolbar.items mutableCopy];
    [toolbarItems removeLastObject];
    [toolbarItems addObject:[[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                            handler:^(id sender) {
                                                                                [blockGallery dismissViewControllerAnimated:YES
                                                                                                           dismissImageView:nil
                                                                                                                 completion:nil];
                                                                                ObservationPhoto *op = self.observationPhotos[blockGallery.presentationIndex];
                                                                                [self.observationPhotos removeObject:op];
                                                                                [op deleteEntity];
                                                                                [self refreshCoverflowView];
                                                                            }]];
    dispatch_async(dispatch_get_main_queue(), ^{
        galleryController.imageViewerViewController.toolbar.items = toolbarItems;
    });
}

#pragma mark UIViewController
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case DeleteActionSheetTag:
            [self deleteActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
            break;
        case ViewActionSheetTag:
            [self viewActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
            break;
        case GeoprivacyActionSheetTag:
            [self geoprivacyActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
            break;
        default:
            [self locationActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
            break;
    }
}

- (void)locationActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // can't declare even anonymous blocks in switch statements
    void(^segueBlock)() = ^ {
        [self performSegueWithIdentifier:@"EditLocationSegue" sender:self];
    };
    
    switch (buttonIndex) {
        case 0:
            [self startUpdatingLocation];
            break;
        case 1:
            // can only -presentViewController once at a time
            // on iOS 8/iPad, this action sheet was presented
            // so perform the segue after the sheet has dismissed
            dispatch_async(dispatch_get_main_queue(), segueBlock);
            break;
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)deleteActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        // no point in querying location anymore
        [self.locationManager stopUpdatingLocation];

        [self.observation destroy];
        self.observation = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(observationDetailViewControllerDidSave:)]) {
            [self.delegate observationDetailViewControllerDidSave:self];
        }
        NSNotification *syncNotification = [NSNotification notificationWithName:INatUserSavedObservationNotification
                                                                         object:self.observation];
        [[NSNotificationCenter defaultCenter] postNotification:syncNotification];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        NSURL *url = [NSURL URLWithString:
                      [NSString stringWithFormat:@"%@/observations/%d", INatWebBaseURL, [self.observation.recordID intValue]]];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)geoprivacyActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self uiToObservation];
    switch (buttonIndex) {
        case 0:
            self.observation.geoprivacy = NSLocalizedString( @"open_adj",nil);
            break;
        case 1:
            self.observation.geoprivacy = NSLocalizedString(@"obscured",nil);
            break;
        case 2:
            self.observation.geoprivacy = NSLocalizedString(@"private",nil);
            break;
        default:
            break;
    }
    [self observationToUI];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark PhotoViewControllerDelegate
/*
 TODO: need to re-implement delete photo
- (void)photoViewControllerDeletePhoto:(id<TTPhoto>)photo
{
    ObservationPhoto *op = (ObservationPhoto *)photo;
    [self.observationPhotos removeObject:op];
    [op deleteEntity];
    [self refreshCoverflowView];
}
 */

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (newLocation.timestamp.timeIntervalSinceNow < -60) return;
    if (!self.locationUpdatesOn) return;
    
    @try {
        self.observation.latitude = [NSNumber numberWithDouble:newLocation.coordinate.latitude];
        self.observation.longitude =[NSNumber numberWithDouble:newLocation.coordinate.longitude];
        self.observation.privateLatitude = nil;
        self.observation.privateLongitude = nil;
        self.observation.positionalAccuracy = [NSNumber numberWithDouble:newLocation.horizontalAccuracy];
        self.observation.positioningMethod = @"gps";
        
        if (self.latitudeLabel) {
            self.latitudeLabel.text = [NSString stringWithFormat:@"%f", newLocation.coordinate.latitude];
            self.longitudeLabel.text = [NSString stringWithFormat:@"%f", newLocation.coordinate.longitude];
            self.positionalAccuracyLabel.text = [NSString stringWithFormat:@"%d",
                                                 [self.observation.positionalAccuracy intValue]];
        }
        
        if (newLocation.horizontalAccuracy < 10) {
            [self stopUpdatingLocation];
        }
        
        if (self.observation.placeGuess.length == 0 || [newLocation distanceFromLocation:oldLocation] > 100) {
            [self reverseGeocodeCoordinates];
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

# pragma mark - TableViewDelegate methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == ProjectsSection) {
        return self.observation.projectObservations.count + 1;
    } else if (section == MoreSection) {
        return self.observationFieldValues.count + 2;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The projects section is composed of one static cell and n dynamic cells.  
    // So we intercept dataSource calls to create those dynamic cells here
    // https://devforums.apple.com/message/505098
    if (indexPath.section == ProjectsSection) {
        
        // if this is anything other than the last cell, create a dynamic cell
        if (indexPath.row < self.observation.projectObservations.count) {
            return [self tableView:tableView projectCellForRowAtIndexPath:indexPath];
        }
        
        // otherwise reset the indexPath so the table view thinks it's retrieving the static cell at index 0
        indexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
    } else if (indexPath.section == MoreSection) {
        if (indexPath.row > 1) {
            return [self tableView:tableView observationFieldValueCellForRowAtIndexPath:indexPath];
        }
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView projectCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                   reuseIdentifier:@"ProjectCell"];
    [cell setBackgroundColor:[UIColor whiteColor]];
    ProjectObservation *po = [self.observation.sortedProjectObservations objectAtIndex:indexPath.row];
    
    float imageMargin = 5;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(imageMargin,imageMargin,33,33)];
    [imageView sd_cancelCurrentImageLoad];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView sd_setImageWithURL:[NSURL URLWithString:po.project.iconURL]
                 placeholderImage:[UIImage imageNamed:@"projects"]];
    [imageView setBackgroundColor:[UIColor clearColor]];
    [cell.contentView addSubview:imageView];
    
    float labelWidth = cell.bounds.size.width - imageView.frame.size.width 
        - imageMargin
        - imageMargin
        - 30;// ??
    UILabel *label = [[UILabel alloc] initWithFrame:
                      CGRectMake(imageView.bounds.size.width + imageMargin + imageMargin, 
                                 0, 
                                 labelWidth,
                                 43)];
    label.text = po.project.title;
    [cell.contentView addSubview:label];
    label.font = [UIFont boldSystemFontOfSize:17];
    return cell;
}

// Note that the technique employed here of loading the nib every time we create a cell could 
// be a performance problem, at least when the cells first appear. Using normal cell dequeing 
// works, but doesn't seem to preserve the state of text fields in the cells
- (UITableViewCell *)tableView:(UITableView *)tableView observationFieldValueCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ObservationFieldValue *ofv = [self observationFieldValueForIndexPath:indexPath];
    if (!ofv.value) {
        ofv.value = ofv.defaultValue;
    }
    UITableViewCell *cell = [self.ofvCells objectForKey:ofv.observationField.name];
    if (cell) {
        return cell;
    }
    if (ofv.observationField.allowedValuesArray.count == 2) {
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:ObservationFieldValueSwitchCell owner:self options:nil];
        cell = [nibObjects objectAtIndex:0];
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        DCRoundSwitch *roundSwitch = (DCRoundSwitch *)[cell viewWithTag:2];
        label.text = ofv.observationField.name;
        roundSwitch.onText = [[ofv.observationField.allowedValuesArray firstObject] uppercaseString];
        roundSwitch.offText = [[ofv.observationField.allowedValuesArray lastObject] uppercaseString];
        [roundSwitch setOn:[ofv.value isEqualToString:[ofv.observationField.allowedValuesArray firstObject]]];
        if ([self projectsRequireField:ofv.observationField].count > 0) {
            label.textColor = [UIColor colorWithRed:1 green:20.0/255 blue:147.0/255 alpha:1];
        }
    } else if (ofv.observationField.allowedValuesArray.count > 2) {
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:ObservationFieldValueStaticCell owner:self options:nil];
        cell = [nibObjects objectAtIndex:0];
        UILabel *leftLabel = (UILabel *)[cell viewWithTag:1];
        UILabel *rightLabel = (UILabel *)[cell viewWithTag:2];
        leftLabel.text = ofv.observationField.name;
        rightLabel.text = ofv.value == nil ? ofv.defaultValue : ofv.value;
        if ([self projectsRequireField:ofv.observationField].count > 0) {
            leftLabel.textColor = [UIColor colorWithRed:1 green:20.0/255 blue:147.0/255 alpha:1];
        }
    } else if ([ofv.observationField.datatype isEqualToString:@"taxon"]) {
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:ObservationFieldValueStaticCell owner:self options:nil];
        cell = [nibObjects objectAtIndex:0];
        UILabel *leftLabel = (UILabel *)[cell viewWithTag:1];
        UILabel *rightLabel = (UILabel *)[cell viewWithTag:2];
        leftLabel.text = ofv.observationField.name;
        Taxon *t = [Taxon objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID = %@", ofv.value]];
        if (t) {
            rightLabel.text = t.name;
        } else {
            rightLabel.text = ofv.value.length == 0 ? @"unknown" : ofv.value;
        }
    } else {
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:ObservationFieldValueDefaultCell owner:self options:nil];
        cell = [nibObjects objectAtIndex:0];
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        UITextField *textField = (UITextField *)[cell viewWithTag:2];
        label.text = ofv.observationField.name;
        textField.text = ofv.value;
        textField.delegate = self;
        if ([self projectsRequireField:ofv.observationField].count > 0) {
            textField.placeholder = @"required";
            label.textColor = [UIColor colorWithRed:1 green:20.0/255 blue:147.0/255 alpha:1];
        }
        if ([ofv.observationField.datatype isEqualToString:@"numeric"]) {
            textField.keyboardType = UIKeyboardTypeDecimalPad;
        }
    }
    [self.ofvCells setObject:cell forKey:ofv.observationField.name];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TaxonTableViewSection && self.observation.taxon) {
        TaxonDetailViewController *tdvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"TaxonDetailViewController"];
        tdvc.taxon = self.observation.taxon;
        [self.navigationController pushViewController:tdvc animated:YES];
    } else if (indexPath.section == LocationTableViewSection) {
        UIActionSheet *locationActionSheet = [[UIActionSheet alloc] init];
        locationActionSheet.delegate = self;
        locationActionSheet.tag = LocationActionSheetTag;
        [locationActionSheet addButtonWithTitle:NSLocalizedString(@"Get current location",nil)];
        [locationActionSheet addButtonWithTitle:NSLocalizedString(@"Edit location",nil)];
        [locationActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
        [locationActionSheet setCancelButtonIndex:2];
        if (self.tabBarController)
            [locationActionSheet showFromTabBar:self.tabBarController.tabBar];
        else
            [locationActionSheet showInView:self.view];
    } else if (indexPath.section == ObservedOnTableViewSection) {
        
        [ActionSheetDatePicker showPickerWithTitle:NSLocalizedString(@"Choose a date", nil)
                                    datePickerMode:UIDatePickerModeDateAndTime
                                      selectedDate:self.observation.localObservedOn ?: [NSDate date]
                                         doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                             
                                             self.observation.localObservedOn = selectedDate;
                                             self.observation.observedOnString = [Observation.jsDateFormatter stringFromDate:selectedDate];
                                             self.observedAtLabel.text = [self.observation observedOnPrettyString];
                                             
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                 [self.getToolbarViewController.navigationController setToolbarHidden:NO animated:YES];
                                             });
                                             [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
                                         } cancelBlock:^(ActionSheetDatePicker *picker) {
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                 [self.getToolbarViewController.navigationController setToolbarHidden:NO animated:YES];
                                             });
                                             [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
                                         } origin:[self tableView:self.tableView cellForRowAtIndexPath:indexPath]];
        
    } else if (indexPath.section == ProjectsSection && indexPath.row < self.observation.projectObservations.count) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == MoreSection && indexPath.row == 1) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose how your coordinates are displayed on the website.",nil)
                                                                 delegate:self 
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Open_adj",nil),
                                                                            NSLocalizedString(@"Obscured",nil),
                                                                            NSLocalizedString(@"Private",nil), nil];
        actionSheet.tag = GeoprivacyActionSheetTag;
        self.currentActionSheet = actionSheet;
        if (self.tabBarController)
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        else
            [actionSheet showInView:self.view];
    } else if (indexPath.section == MoreSection && indexPath.row > 1) {
        [self didSelectObservationFieldValueRow:indexPath];
    } else {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (void)didSelectObservationFieldValueRow:(NSIndexPath *)indexPath
{
    ObservationFieldValue *ofv = [self.observationFieldValues objectAtIndex:indexPath.row - 2];
    if (ofv.observationField.allowedValuesArray.count > 2) {
        NSInteger index = [ofv.observationField.allowedValuesArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [obj isEqualToString:ofv.value];
        }];
        if (index < 1 || index >= ofv.observationField.allowedValuesArray.count) {
            index = 0;
        }
        UITableViewCell *cell = [self tableView:self.tableView observationFieldValueCellForRowAtIndexPath:indexPath];
        // be defensive
        if (self.view.window) {
            [ActionSheetStringPicker showPickerWithTitle:ofv.observationField.name
                                                    rows:ofv.observationField.allowedValuesArray
                                        initialSelection:index
                                               doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                   UILabel *label = (UILabel *)[cell viewWithTag:2];
                                                   label.text = selectedValue;
                                                   ofv.value = selectedValue;
                                                   [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                                               }
                                             cancelBlock:^(ActionSheetStringPicker *picker) {
                                                 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                                             }
                                                  origin:cell];
        }
    } else if ([ofv.observationField.datatype isEqualToString:@"taxon"]) {
        [self performSegueWithIdentifier:@"OFVTaxonSegue" sender:self];
    } else {
        if (!ofv.observationField.desc) {
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
            return;
        }
        NSMutableString *msg = [NSMutableString stringWithString:ofv.observationField.desc];
        NSArray *projects = [self projectsRequireField:ofv.observationField];
        if (projects.count > 0) {
            [msg appendFormat:NSLocalizedString(@"\n\nRequired by %@",nil), [[projects valueForKey:@"title"] componentsJoinedByString:@", "]];
        }
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:ofv.observationField.name
                                                     message:msg
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ProjectsSection || indexPath.section == MoreSection) {
        return 44;
    } else if (indexPath.section == NotesTableViewSection && self.observation.inatDescription.length > 0) {
        NSString *txt = self.observation.inatDescription;
        CGFloat defaultHeight = [super tableView:tableView heightForRowAtIndexPath:indexPath];
        float fontSize;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            fontSize = 12;
        } else {
            fontSize = 17;
        }
        CGSize size = [txt sizeWithFont:[UIFont systemFontOfSize:fontSize]
                      constrainedToSize:CGSizeMake(320.0, 10000.0)
                          lineBreakMode:NSLineBreakByWordWrapping];
        return MAX(defaultHeight, size.height);
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (self.observationPhotos.count == 0) {
            return nil;
        } else {
            CGRect r = CGRectMake(0, 0, tableView.bounds.size.width, [tableView.delegate tableView:tableView heightForHeaderInSection:section]);
            self.coverflowView = [[TKCoverflowView alloc] initWithFrame:r];
            self.coverflowView.coverflowDelegate = self;
            self.coverflowView.coverflowDataSource = self;
            self.coverflowView.coverSize = CGSizeMake(r.size.width - 80, r.size.height - 40);
            self.coverflowView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            return self.coverflowView;
        }
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (self.observationPhotos.count == 0) {
            return 44;
        } else {
            return tableView.bounds.size.width / 1.342;
        }
    } else {
        return 44;
    }
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

# pragma mark - EditLocationViewControllerDelegate
- (void)editLocationViewControllerDidSave:(EditLocationViewController *)controller location:(INatLocation *)location
{
    self.latitudeLabel.text = [NSString stringWithFormat:@"%f", [location.latitude doubleValue]];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%f", [location.longitude doubleValue]];
    self.observation.positioningMethod = location.positioningMethod;
    if (location.accuracy) {
        self.positionalAccuracyLabel.text = [NSString stringWithFormat:@"%d", [location.accuracy intValue]];
    } else {
        self.positionalAccuracyLabel.text = @"???";
    }
    [self reverseGeocodeCoordinates];
}

# pragma mark - ProjectChooserViewControllerDelegate
- (void)projectChooserViewController:(ProjectChooserViewController *)controller 
                       choseProjects:(NSArray *)projects
{
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
    
    for (Project *p in newProjects) {
        ProjectObservation *po = [ProjectObservation object];
        po.observation = self.observation;
        po.project = p;
        self.observation.localUpdatedAt = [NSDate date];
    }
    [self reloadObservationFieldValues];
    [self.tableView reloadData];
    [self observationToUI];
}

#pragma mark - TaxaSearchViewControllerDelegate
- (void)taxaSearchViewControllerChoseTaxon:(Taxon *)taxon
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.observation.taxon = taxon;
    self.observation.taxonID = taxon.recordID;
    self.observation.iconicTaxonName = taxon.iconicTaxonName;
    self.observation.iconicTaxonID = taxon.iconicTaxonID;
    self.observation.speciesGuess = taxon.defaultName;
    [self observationToUI];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // right now the only alert view is for existing asset processing
    if (buttonIndex == 1) {
        [self stopUpdatingLocation];
        ALAssetsLibrary *assetsLib = [[ALAssetsLibrary alloc] init];
        [assetsLib assetForURL:self.lastImageReferenceURL resultBlock:^(ALAsset *asset) {
            [self uiToObservation];
            // extract the metadata
            NSDate *imageDate = [asset valueForProperty:ALAssetPropertyDate];
            if (imageDate) {
                self.observation.localObservedOn = imageDate;
                self.observation.observedOnString = [Observation.jsDateFormatter stringFromDate:imageDate];
            }
            CLLocation *imageLoc = [asset valueForProperty:ALAssetPropertyLocation];
            if (imageLoc) {
                self.observation.latitude = [NSNumber numberWithDouble:imageLoc.coordinate.latitude];
                self.observation.longitude = [NSNumber numberWithDouble:imageLoc.coordinate.longitude];
                if (imageLoc.horizontalAccuracy && imageLoc.horizontalAccuracy > 0) {
                    self.observation.positionalAccuracy = [NSNumber numberWithDouble:imageLoc.horizontalAccuracy];
                } else {
                    self.observation.positionalAccuracy = nil;
                }
            } else {
                self.observation.placeGuess = nil;
                self.observation.latitude = nil;
                self.observation.longitude = nil;
                self.observation.positionalAccuracy = nil;
                self.observation.positioningMethod = nil;
                self.observation.positioningDevice = nil;
            }
            [self observationToUI];
            if (self.observation.latitude) {
                [self reverseGeocodeCoordinates];
            }
            self.lastImageReferenceURL = nil;
        } failureBlock:^(NSError *error) {
            NSString *msg = error.localizedFailureReason;
            if (error.code == ALAssetsLibraryAccessUserDeniedError) {
                msg = NSLocalizedString(@"You've denied iNaturalist access to certain kinds of data, most likely location data, so some of the photo data couldn't be imported.  To change this, open your Settings app, click Location Services, and make sure Location Services are on for iNaturalist.",nil);
            }
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import Error",nil)
                                                         message:msg
                                                        delegate:nil 
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                               otherButtonTitles:nil];
            [av show];
            self.lastImageReferenceURL = nil;
        }];
    } else {
        self.lastImageReferenceURL = nil;
    }
}

#pragma mark - ObservationDetailViewController

- (void)focusOnPrevField
{
    UIView *curr = [self.view findFirstResponder];
    UIView *cell = curr.superview;
    while (cell && ![cell isKindOfClass:UITableViewCell.class]) {
        cell = [cell superview];
    }
    if (cell) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)cell];
        // check prev siblings
        for (NSInteger row = indexPath.row-1; row >= 0; row--) {
            if ([self focusOnFieldAtIndexPath:[NSIndexPath indexPathForRow:row inSection:indexPath.section]]) {
                return;
            }
        }
        // check prev sections
        for (NSInteger section = indexPath.section-1; section >= 0; section--) {
            for (NSInteger row = [self.tableView numberOfRowsInSection:section]-1; row >= 0; row--) {
                if ([self focusOnFieldAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]) {
                    return;
                }
            }
        }
    }
}

- (void)focusOnNextField
{
    UIView *curr = [self.view findFirstResponder];
    UIView *cell = curr.superview;
    while (cell && ![cell isKindOfClass:UITableViewCell.class]) {
        cell = [cell superview];
    }
    if (cell) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)cell];
        // check next siblings
        for (NSInteger row = indexPath.row+1; row < [self.tableView numberOfRowsInSection:indexPath.section]; row++) {
            if ([self focusOnFieldAtIndexPath:[NSIndexPath indexPathForRow:row inSection:indexPath.section]]) {
                return;
            }
        }
        // check next sections
        for (NSInteger section = indexPath.section+1; section < self.tableView.numberOfSections; section++) {
            for (int row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
                if ([self focusOnFieldAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]) {
                    return;
                }
            }
        }
    }
}

- (BOOL)focusOnFieldAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
    UIView *field = [cell descendentPassingTest:^BOOL (UIView *v) {
        if ([v isKindOfClass:UITextField.class] || [v isKindOfClass:UITextView.class]) {
            return [v isKindOfClass:UITextField.class] ? [(UITextField *)v isEnabled] : YES;
        } else {
            return NO;
        }
    }];
    if (field) {
        [field becomeFirstResponder];
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionTop 
                                      animated:YES];
        return YES;
    }
    return NO;
}

- (void)keyboardDone {
    [[self.view findFirstResponder] resignFirstResponder];
}

- (void)clickedSave {
    [self stopUpdatingLocation];
    if (![self validate]) {
        return;
    }
    [self save];
    if (self.delegate && [self.delegate respondsToSelector:@selector(observationDetailViewControllerDidSave:)]) {
        [self.delegate observationDetailViewControllerDidSave:self];
    }
    NSNotification *syncNotification = [NSNotification notificationWithName:INatUserSavedObservationNotification 
                                                                     object:self.observation];
    [[NSNotificationCenter defaultCenter] postNotification:syncNotification];
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)validate
{
    [self uiToObservation];
    for (ProjectObservation *po in self.observation.projectObservations) {
        for (ProjectObservationField *pof in po.project.projectObservationFields) {
            if (pof.required.boolValue) {
                ObservationFieldValue *ofv = [[self.observation.observationFieldValues objectsPassingTest:^BOOL(ObservationFieldValue *obj, BOOL *stop) {
                    return [obj.observationField isEqual:pof.observationField];
                }] anyObject];
                if (!ofv || ofv.value == nil || ofv.value.length == 0) {
                    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"%@ requires that you fill out the %@ field",nil),
                                     pof.project.title, 
                                     pof.observationField.name];
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Field",nil)
                                                                 message:msg
                                                                delegate:nil 
                                                       cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                       otherButtonTitles:nil];
                    [av show];
                    return false;
                }
            }
        }
    }
    return true;
}

- (void)clickedDelete
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil 
                                                             delegate:self 
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                               destructiveButtonTitle:NSLocalizedString(@"Delete observation",nil)
                                                    otherButtonTitles:nil];
    actionSheet.tag = DeleteActionSheetTag;
    [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
    
    // be defensive
    if (self.view.window) {
        [actionSheet showFromBarButtonItem:self.viewButton animated:YES];
    }
}

- (void)clickedView
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil 
                                                             delegate:self 
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"View on iNaturalist.org",nil), nil];
    actionSheet.tag = ViewActionSheetTag;
    
    // be defensive
    if (self.view.window) {
        [actionSheet showFromBarButtonItem:self.viewButton animated:YES];
    }
}

- (void)clickedActivity:(id)sender
{
	ObservationActivityViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL]
									  instantiateViewControllerWithIdentifier:@"ObservationActivityViewController"];
	vc.observation = self.observation;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)save
{
    if (self.observation.isNew) {
        [[Analytics sharedClient] event:kAnalyticsEventCreateObservation
                         withProperties:@{ @"Project": @(self.observation.projectObservations.count > 0) }];
    }
    
    [self uiToObservation];
    NSDictionary *changes = self.observation.attributeChanges;
    NSDate *now = [NSDate date];
    for (ObservationFieldValue *ofv in self.observation.observationFieldValues) {
        if (ofv.attributeChanges.count > 0) {
            ofv.localUpdatedAt = now;
        }
    }
    for (ProjectObservation *po in self.observation.projectObservations) {
        if (po.attributeChanges.count > 0) {
            po.localUpdatedAt = now;
        }
    }
    if (changes.count > 0) {
        self.observation.localUpdatedAt = now;
    }
	[self.observation save];
}

- (IBAction)clickedCancel:(id)sender {
    self.didClickCancel = YES;
    [self stopUpdatingLocation];
    if (self.observationWasNew) {
        [self.observation deleteEntity];
        self.observation = nil;
    } else {
        [self.observation.managedObjectContext rollback];
    }
    if ([self.delegate respondsToSelector:@selector(observationDetailViewControllerDidCancel:)]) {
        [self.delegate observationDetailViewControllerDidCancel:self];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)reverseGeocodeLocation:(CLLocation *)loc forObservation:(Observation *)obs {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
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
                           } @catch (NSException *exception) {
                               if ([exception.name isEqualToString:NSObjectInaccessibleException])
                                   return;
                               else
                                   @throw exception;
                           }
                       }
                   }];
    
}

#pragma mark - QBImagePicker delegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets {
    // add to observation
    
    __weak __typeof__(self) weakSelf = self;
    [self.observation addAssets:assets
                      afterEach:^(ObservationPhoto *op) {
                          __typeof__(self) strongSelf = weakSelf;
                          if (strongSelf) {
                              [strongSelf addPhoto:op];
                          }
                      }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}


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


- (IBAction)clickedAddPhoto:(id)sender {
    
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
}

- (IBAction)clickedSpeciesButton:(id)sender {
    if (self.observation && self.observation.taxon) {
        if ([self.observation.speciesGuess isEqualToString:self.observation.taxon.defaultName]) {
            self.observation.speciesGuess = nil;
        }
        self.observation.taxon = nil;
        self.observation.taxonID = nil;
        self.observation.iconicTaxonID = nil;
        self.observation.iconicTaxonName = nil;
        [self observationToUI];
    } else {
        [self performSegueWithIdentifier:@"TaxaSearchSegue" sender:nil];
    }
}

- (void)setObservation:(Observation *)observation
{
    _observation = observation;
    
    if (observation && [observation.observationPhotos count] > 0) {
        for (ObservationPhoto *op in observation.sortedObservationPhotos) {
            [self.observationPhotos addObject:op];
        }
        [self refreshCoverflowView];
    } else {
        [self.observationPhotos removeAllObjects];
    }
    self.observationWasNew = [observation isNew];
}

- (NSMutableArray *)observationPhotos
{
    if (!_observationPhotos) {
        self.observationPhotos = [[NSMutableArray alloc] init];
    }
    return _observationPhotos;
}

- (NSMutableArray *)observationFieldValues
{
    if (!_observationFieldValues) {
        self.observationFieldValues = [[NSMutableArray alloc] init];
    }
    return _observationFieldValues;
}

- (NSMutableDictionary *)ofvCells
{
    if (!_ofvCells) {
        self.ofvCells = [[NSMutableDictionary alloc] init];
    }
    return _ofvCells;
}

- (void)reloadObservationFieldValues
{
    [self.observationFieldValues removeAllObjects];
    [self.ofvCells removeAllObjects];
    NSMutableSet *existing = [NSMutableSet setWithSet:self.observation.observationFieldValues];
    
    for (ProjectObservation *po in self.observation.projectObservations) {
        for (ProjectObservationField *pof in po.project.sortedProjectObservationFields) {
            ObservationFieldValue *ofv = [[existing objectsPassingTest:^BOOL(ObservationFieldValue *obj, BOOL *stop) {
                return [obj.observationField isEqual:pof.observationField];
            }] anyObject];
            if (!ofv) {
                ofv = [ObservationFieldValue object];
                ofv.observation = self.observation;
                ofv.observationField = pof.observationField;
            }
            if (![self.observationFieldValues containsObject:ofv]) {
                [self.observationFieldValues addObject:ofv];
                [existing removeObject:ofv];
            }
        }
    }
    for (ObservationFieldValue *remaining in existing) {
        [self.observationFieldValues addObject:remaining];
    }
}

- (void)addPhoto:(ObservationPhoto *)op
{
    [self.observationPhotos addObject:op];
    [self refreshCoverflowView];
    [self.coverflowView setCurrentCoverIndex:[self.coverflowView.coverflowDataSource numberOfCoversInCoverflowView:self.coverflowView] - 1];
}

- (void)removePhoto:(ObservationPhoto *)op
{
    [self.observationPhotos removeObject:op];
    [self refreshCoverflowView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self stopUpdatingLocation];
    [self uiToObservation];
    if ([segue.identifier isEqualToString:@"EditLocationSegue"]) {
        EditLocationViewController *vc = (EditLocationViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        if (self.observation.visibleLatitude) {
            INatLocation *loc = [[INatLocation alloc] initWithLatitude:self.observation.visibleLatitude
                                                             longitude:self.observation.visibleLongitude
                                                              accuracy:self.observation.positionalAccuracy];
            loc.positioningMethod = self.observation.positioningMethod;
            [vc setCurrentLocation:loc];
        } else {
            [vc setCurrentLocation:nil];
        }
    } else if ([segue.identifier isEqualToString:@"ProjectChooserSegue"]) {
        ProjectChooserViewController *vc = (ProjectChooserViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        NSMutableArray *projects = [[NSMutableArray alloc] init];
        for (ProjectObservation *po in self.observation.projectObservations) {
            [projects addObject:po.project];
        }
        vc.chosenProjects = projects;
    } else if ([segue.identifier isEqualToString:@"TaxaSearchSegue"]) {
        TaxaSearchViewController *vc = (TaxaSearchViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        vc.query = self.observation.speciesGuess;
    } else if ([segue.identifier isEqualToString:@"OFVTaxonSegue"]) {
        TaxaSearchViewController *vc = (TaxaSearchViewController *)[segue.destinationViewController topViewController];
        self.ofvTaxaSearchControllerDelegate.indexPath = [self.tableView indexPathForSelectedRow];
        ObservationFieldValue *ofv = [self observationFieldValueForIndexPath:self.ofvTaxaSearchControllerDelegate.indexPath];
        Taxon *t = [Taxon objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID = %@", ofv.value]];
        vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear",nil)
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(clearCurrentObservationField)];
        if (t) {
            vc.query = t.name;
        }
        [vc setDelegate:self.ofvTaxaSearchControllerDelegate];
    }
}

- (void)startUpdatingLocation
{
    self.locationUpdatesOn = YES;
    UITableViewCell *locationCell = [self.tableView cellForRowAtIndexPath:
                                     [NSIndexPath indexPathForRow:0 inSection:2]];
    UIActivityIndicatorView *av = (UIActivityIndicatorView *)[locationCell viewWithTag:1];
    UIImageView *img = (UIImageView *)[locationCell viewWithTag:2];
    [av startAnimating];
    img.hidden = YES;
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        self.locationManager.delegate = self;
    }
    if (!self.locationTimer) {
        self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 
                                                              target:self 
                                                            selector:@selector(stopUpdatingLocation) 
                                                            userInfo:nil 
                                                             repeats:NO];
    }
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation
{
    self.locationUpdatesOn = NO;
    if (self.isViewLoaded && self.tableView) {
        UITableViewCell *locationCell = [self tableView:self.tableView cellForRowAtIndexPath:
                                         [NSIndexPath indexPathForRow:0 inSection:LocationTableViewSection]];
        if (locationCell) {
            UIActivityIndicatorView *av = (UIActivityIndicatorView *)[locationCell viewWithTag:1];
            UIImageView *img = (UIImageView *)[locationCell viewWithTag:2];
            [av stopAnimating];
            img.hidden = NO;
        }
    }
    
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
    if (self.locationTimer) {
        [self.locationTimer invalidate];
    }
}

- (void)reverseGeocodeCoordinates
{
    if (self.placeGuessField) {
        self.placeGuessField.text = nil;
    }
    [self uiToObservation];
    
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:[self.observation.visibleLatitude doubleValue]
                                                 longitude:[self.observation.visibleLongitude doubleValue]];
    if (!self.geocoder) {
        self.geocoder = [[CLGeocoder alloc] init];
    }
    [self.geocoder cancelGeocode];
    [self.geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *pm = [placemarks firstObject]; 
        if (pm) {
            // self.observation may not be accessible
            // if it's been deleted for example
            @try {
                self.observation.placeGuess = [[NSArray arrayWithObjects:
                                                pm.name,
                                                pm.locality,
                                                pm.administrativeArea,
                                                pm.ISOcountryCode,
                                                nil]
                                               componentsJoinedByString:@", "];
                if (self.placeGuessField) {
                    self.placeGuessField.text = self.observation.placeGuess;
                }
            } @catch (NSException *exception) {
                if ([exception.name isEqualToString:NSObjectInaccessibleException])
                    return;
                else
                    @throw exception;
            }
        }
    }];
}

- (void)dismissActionSheet
{
    if (!self.currentActionSheet) return;
    [self.currentActionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (NSArray *)projectsRequireField:(ObservationField *)observationField
{
    NSMutableArray *a = [[NSMutableArray alloc] init];
    for (ProjectObservation *po in self.observation.projectObservations) {
        for (ProjectObservationField *pof in po.project.projectObservationFields) {
            if ([pof.observationField isEqual:observationField] && pof.required.boolValue) {
                [a addObject:pof.project];
            }
        }
    }
    return a;
}

- (ObservationFieldValue *)observationFieldValueForIndexPath:(NSIndexPath *)indexPath
{
    return [self.observationFieldValues objectAtIndex:(indexPath.row - 2)];
}

- (void)clearCurrentObservationField
{
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    ObservationFieldValue *ofv = [self observationFieldValueForIndexPath:indexPath];
    if (ofv) {
        ofv.value = nil;
        [self.ofvCells removeObjectForKey:ofv.observationField.name];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

@end
