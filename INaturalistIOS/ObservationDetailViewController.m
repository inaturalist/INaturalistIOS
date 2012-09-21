//
//  INObservationFormViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ObservationDetailViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import "ObservationField.h"
#import "ObservationFieldValue.h"
#import "PhotoViewController.h"
#import "PhotoSource.h"
#import "Project.h"
#import "ProjectObservation.h"
#import "ProjectObservationField.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "EditLocationViewController.h"

static const int PhotoActionSheetTag = 0;
static const int LocationActionSheetTag = 1;
static const int ObservedOnActionSheetTag = 2;
static const int DeleteActionSheetTag = 3;
static const int ViewActionSheetTag = 4;
static const int GeoprivacyActionSheetTag = 5;
static const int LocationTableViewSection = 2;
static const int ObservedOnTableViewSection = 3;
static const int MoreSection = 4;
static const int ProjectsSection = 5;
NSString *const ObservationFieldValueDefaultCell = @"ObservationFieldValueDefaultCell";
NSString *const ObservationFieldValueSwitchCell = @"ObservationFieldValueSwitchCell";

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
@synthesize datePicker = _datePicker;
@synthesize popOver = _popOver;
@synthesize currentActionSheet = _currentActionSheet;
@synthesize locationUpdatesOn = _locationUpdatesOn;
@synthesize observationWasNew = _observationWasNew;
@synthesize lastImageReferenceURL = _lastImageReferenceURL;
@synthesize ofvCells = _ofvCells;

- (void)observationToUI
{
    if (!self.observation) return;
    [self.speciesGuessTextField setText:self.observation.speciesGuess];
    [self.observedAtLabel setText:self.observation.observedOnPrettyString];
    [self.placeGuessField setText:self.observation.placeGuess];
    if (self.observation.latitude) {
        [self.latitudeLabel setText:self.observation.latitude.description];
    } else {
        self.latitudeLabel.text = nil;
    }
    if (self.observation.longitude) {
        [self.longitudeLabel setText:self.observation.longitude.description];
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
    TTImageView *img = (TTImageView *)[speciesCell viewWithTag:1];
    UIButton *rightButton = (UIButton *)[speciesCell viewWithTag:3];
    img.style = [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithTopLeft:5 
                                                                              topRight:5 
                                                                           bottomRight:5 
                                                                            bottomLeft:5] 
                                        next:[TTContentStyle styleWithNext:nil]];
    [img unsetImage];
    img.defaultImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.observation.iconicTaxonName];
    if (self.observation.taxon) {
        if (self.observation.taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = (TaxonPhoto *)self.observation.taxon.taxonPhotos.firstObject;
            img.urlPath = tp.squareURL;
        }
        self.speciesGuessTextField.enabled = NO;
        rightButton.imageView.image = [UIImage imageNamed:@"298-circlex.png"];
        self.speciesGuessTextField.textColor = [Taxon iconicTaxonColor:self.observation.iconicTaxonName];
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
    if (![self.observation.speciesGuess isEqualToString:self.speciesGuessTextField.text]) {
        [self.observation setSpeciesGuess:[self.speciesGuessTextField text]];
    }
    if (![self.observation.speciesGuess isEqualToString:self.descriptionTextView.text]) {
        [self.observation setInatDescription:[descriptionTextView text]];
    }
    if (![self.observation.placeGuess isEqualToString:self.placeGuessField.text]) {
        [self.observation setPlaceGuess:[self.placeGuessField text]];
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setLocale:[NSLocale systemLocale]];
    NSNumber *newLat = [numberFormatter numberFromString:self.latitudeLabel.text];
    NSNumber *newLon = [numberFormatter numberFromString:self.longitudeLabel.text];
    NSNumber *newAcc = [numberFormatter numberFromString:self.positionalAccuracyLabel.text];
    if (![self.observation.latitude isEqualToNumber:newLat]) {
        self.observation.latitude = newLat;
    }
    if (![self.observation.longitude isEqualToNumber:newLon]) {
        self.observation.longitude = newLon;
    }
    if (![self.observation.positionalAccuracy isEqualToNumber:newAcc]) {
        self.observation.positionalAccuracy = newAcc;
    }
    self.observation.idPlease = [NSNumber numberWithBool:self.idPleaseSwitch.on];
    
    for (NSString *key in self.ofvCells) {
        UITableViewCell *cell = [self.ofvCells objectForKey:key];
        NSUInteger ofvIndex = [self.observationFieldValues indexOfObjectPassingTest:^BOOL(ObservationFieldValue *obj, NSUInteger idx, BOOL *stop) {
            return [obj.observationField.name isEqualToString:key];
        }];
        ObservationFieldValue *ofv = [self.observationFieldValues objectAtIndex:ofvIndex];
        if ([cell.reuseIdentifier isEqualToString:ObservationFieldValueSwitchCell]) {
            DCRoundSwitch *roundSwitch = (DCRoundSwitch *)[cell viewWithTag:2];
            if (roundSwitch.on) {
                ofv.value = [ofv.observationField.allowedValuesArray firstObject];
            } else {
                ofv.value = [ofv.observationField.allowedValuesArray lastObject];
            }
        } else {
            UITextField *textField = (UITextField *)[cell viewWithTag:2];
            ofv.value = textField.text;
        }
    }
}

- (void)initUI
{
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] 
                             initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                             target:nil 
                             action:nil];
    if (!self.saveButton) {
        self.saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" 
                                                           style:UIBarButtonItemStyleDone 
                                                          target:self
                                                          action:@selector(clickedSave)];
        [self.saveButton setWidth:100.0];
        [self.saveButton setTintColor:[UIColor colorWithRed:168.0/255 
                                                      green:204.0/255 
                                                       blue:50.0/255 
                                                      alpha:1.0]];
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
    
    [self setToolbarItems:[NSArray arrayWithObjects:
                           self.deleteButton,
                           flex, 
                           self.saveButton, 
                           flex, 
                           self.viewButton,
                           nil]
                 animated:NO];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    if (!self.keyboardToolbar) {
        self.keyboardToolbar = [[UIToolbar alloc] init];
        self.keyboardToolbar.barStyle = UIBarStyleBlackOpaque;
        [self.keyboardToolbar sizeToFit];
        UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] 
                                        initWithTitle:@"Clear" 
                                        style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(clickedClear)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] 
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                       target:self 
                                       action:@selector(keyboardDone)];
        [self.keyboardToolbar setItems:[NSArray arrayWithObjects:clearButton, flex, doneButton, nil]];
    }
    
    self.idPleaseSwitch.onText = @"YES";
    self.idPleaseSwitch.offText = @"NO";
    
    [self refreshCoverflowView];
    [self observationToUI];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self.observation isNew]) {
        [[self navigationItem] setTitle:@"Add observation"];
    } else {
        [[self navigationItem] setTitle:@"Edit observation"];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    // this is dumb, but the TTPhotoViewController forcibly sets the bar style, so we need to reset it
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self initUI];
    if (self.observation.isNew && 
        (
         self.observation.latitude == nil || // observation has no coordinates yet
         self.locationUpdatesOn                              // location updates already started, but view trashed due to mem warning
         )) {
        [self startUpdatingLocation];
    }
    [self.navigationController setToolbarHidden:NO animated:animated];
    [super viewDidAppear:animated];
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
}

- (void)viewWillDisappear:(BOOL)animated
{
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
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
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
    [self dismissModalViewControllerAnimated:YES];
    ObservationPhoto *op = [ObservationPhoto object];
    op.position = [NSNumber numberWithInt:self.observation.observationPhotos.count+1];
    [op setObservation:self.observation];
    [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [ImageStore.sharedImageStore store:image forKey:op.photoKey];
    [self addPhoto:op];
    op.localCreatedAt = [NSDate date];
    
    NSURL *referenceURL = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
    if (referenceURL) {
        self.lastImageReferenceURL = referenceURL;
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Import metadata?" 
                                                     message:@"Do you want to set the date, time, and location of this observation from the photo's metadata?" 
                                                    delegate:self 
                                           cancelButtonTitle:@"No" 
                                           otherButtonTitles:@"Yes", nil];
        [av show];
    } else {
        ALAssetsLibrary *assetsLib = [[ALAssetsLibrary alloc] init];
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:[self.observation.latitude doubleValue] 
                                                     longitude:[self.observation.longitude doubleValue]];
        
        NSMutableDictionary *meta = [NSMutableDictionary dictionaryWithDictionary:[info objectForKey:UIImagePickerControllerMediaMetadata]];
        [meta setValue:[self getGPSDictionaryForLocation:loc] 
                forKey:((NSString * )kCGImagePropertyGPSDictionary)];
        [assetsLib writeImageToSavedPhotosAlbum:image.CGImage
                                       metadata:meta
                                completionBlock:nil];
    }
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
- (void)initCoverflowView
{
    float width = [UIScreen mainScreen].bounds.size.width,
          height = width / 1.342,
          coverDim = height - 10,
          coverWidth = coverDim,
          coverHeight = coverDim;
    CGRect r = CGRectMake(0, 0, width, height);
    self.coverflowView = [[TKCoverflowView alloc] initWithFrame:r];
	self.coverflowView.coverflowDelegate = self;
	self.coverflowView.dataSource = self;
    self.coverflowView.coverSize = CGSizeMake(coverWidth, coverHeight);
    [self.coverflowView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.tableView.tableHeaderView addSubview:self.coverflowView];
}

- (void)refreshCoverflowView
{
    if (!self.coverflowView) {
        [self initCoverflowView];
    }
    if (self.coverflowView.superview != self.tableView.tableHeaderView) {
        [self.tableView.tableHeaderView addSubview:self.coverflowView];
    }
    self.coverflowView.numberOfCovers = [self.observationPhotos count];
    if (self.coverflowView.numberOfCovers == 0) {
        [self.coverflowView setHidden:YES];
    } else {
        [self.coverflowView setHidden:NO];
    }
    [self.coverflowView setNeedsDisplay];
    [self.coverflowView setNeedsLayout];
    [self resizeHeaderView];
}

- (TKCoverflowCoverView *)coverflowView:(TKCoverflowView *)coverflowView coverAtIndex:(int)index
{
    TKCoverflowCoverView *cover = [coverflowView dequeueReusableCoverView];
    if (!cover) {
        CGRect r = CGRectMake(0, 0, coverflowView.coverSize.width, coverflowView.coverSize.height); 
        cover = [[TKCoverflowCoverView alloc] initWithFrame:r];
        cover.baseline = coverflowView.frame.size.height - 20;
    }
    ObservationPhoto *op = [self.observationPhotos objectAtIndex:index];
    UIImage *img = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSmallSize];
    if (!img) img = [[ImageStore sharedImageStore] find:op.photoKey];
    if (img) cover.image = img;
    return cover;
}

- (void)coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasBroughtToFront:(int)index
{
	// required but not required
}

- (void)coverflowView:(TKCoverflowView *)coverflowView coverAtIndexWasSingleTapped:(int)index
{
    ObservationPhoto *op = [self.observationPhotos objectAtIndex:index];
    if (!op) return;
    NSString *photoSourceTitle = [NSString 
                                  stringWithFormat:@"Photos for %@", 
                                  (self.observation.speciesGuess ? self.observation.speciesGuess : @"Something")];
    PhotoSource *photoSource = [[PhotoSource alloc] 
                                initWithPhotos:self.observationPhotos 
                                title:photoSourceTitle];
    PhotoViewController *vc = [[PhotoViewController alloc] initWithPhoto:op];
    vc.delegate = self;
    vc.photoSource = photoSource;
    [self.navigationController setToolbarHidden:YES];
    [self.navigationController pushViewController:vc animated:YES];
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
        case PhotoActionSheetTag:
            [self photoActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
            break;
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

- (void)photoActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger sourceType;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        switch (buttonIndex) {
            case 0:
                sourceType = UIImagePickerControllerSourceTypeCamera;
                break;
            case 1:
                sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                break;
            default:
                return;
        }
    } else {
        if (buttonIndex == 0) {
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        } else {
            return;
        }
    }
    
    [self uiToObservation];
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    [ipc setDelegate:self];
    [ipc setSourceType:sourceType];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:ipc];
        [popover presentPopoverFromRect:CGRectMake(0.0, 0.0, 0.0, 0.0)
                                 inView:self.view
               permittedArrowDirections:UIPopoverArrowDirectionAny
                               animated:YES];
        self.popOver = popover;
    } else {
        [self presentModalViewController:ipc animated:YES];
    }
}

- (void)locationActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self startUpdatingLocation];
            break;
        case 1:
            [self performSegueWithIdentifier:@"EditLocationSegue" sender:self];
            break;            
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)deleteActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
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
                      [NSString stringWithFormat:@"%@/observations/%d", INatBaseURL, [self.observation.recordID intValue]]];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)geoprivacyActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self uiToObservation];
    switch (buttonIndex) {
        case 0:
            self.observation.geoprivacy = @"open";
            break;
        case 1:
            self.observation.geoprivacy = @"obscured";
            break;
        case 2:
            self.observation.geoprivacy = @"private";
            break;
        default:
            break;
    }
    [self observationToUI];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark PhotoViewControllerDelegate
- (void)photoViewControllerDeletePhoto:(id<TTPhoto>)photo
{
    ObservationPhoto *op = (ObservationPhoto *)photo;
    [self.observationPhotos removeObject:op];
    [op deleteEntity];
    [self refreshCoverflowView];
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (newLocation.timestamp.timeIntervalSinceNow < -60) return;
    if (!self.locationUpdatesOn) return;
    
    self.observation.latitude = [NSNumber numberWithDouble:newLocation.coordinate.latitude];
    self.observation.longitude =[NSNumber numberWithDouble:newLocation.coordinate.longitude]; 
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
    TTImageView *imageView = [[TTImageView alloc] initWithFrame:CGRectMake(imageMargin,imageMargin,33,33)];
    [imageView unsetImage];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.defaultImage = [UIImage imageNamed:@"projects"];
    imageView.urlPath = po.project.iconURL;
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
    ObservationFieldValue *ofv = [self.observationFieldValues objectAtIndex:(indexPath.row - 2)];
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
    }
    [self.ofvCells setObject:cell forKey:ofv.observationField.name];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == LocationTableViewSection) {
        UIActionSheet *locationActionSheet = [[UIActionSheet alloc] init];
        locationActionSheet.delegate = self;
        locationActionSheet.tag = LocationActionSheetTag;
        [locationActionSheet addButtonWithTitle:@"Get current location"];
        [locationActionSheet addButtonWithTitle:@"Edit location"];
        [locationActionSheet addButtonWithTitle:@"Cancel"];
        [locationActionSheet setCancelButtonIndex:2];
        [locationActionSheet showFromTabBar:self.tabBarController.tabBar];
    } else if (indexPath.section == ObservedOnTableViewSection) {
        // this is an extremely silly way to get the height right, but the only other 
        // way I've found is to alter the bounds *after* the action sheet has appeared, 
        // which messes up the animation.
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose a date"
                                                           delegate:nil 
                                                  cancelButtonTitle:nil 
                                             destructiveButtonTitle:nil 
                                                  otherButtonTitles:@"", @"", @"", @"", nil];
        self.currentActionSheet = sheet;
        sheet.delegate = self;
        sheet.tag = ObservedOnActionSheetTag;
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        toolbar.barStyle = UIBarStyleBlackTranslucent;
        [toolbar sizeToFit];
        [toolbar setItems:[NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc] 
                            initWithTitle:@"Cancel" 
                            style:UIBarButtonItemStyleBordered 
                            target:self 
                            action:@selector(dismissActionSheet)], 
                           [[UIBarButtonItem alloc] 
                            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                            target:nil 
                            action:nil],
                           [[UIBarButtonItem alloc] 
                            initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                            target:self
                            action:@selector(doneDatePicker)],
                           nil] 
                 animated:YES];
        [sheet addSubview:toolbar];
        
        if (!self.datePicker) {
            self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, toolbar.frame.size.height, 320, 320)];
        }
        self.datePicker.maximumDate = [NSDate date];
        self.datePicker.date = self.observation.localObservedOn;
        [sheet addSubview:self.datePicker];
        [sheet showFromTabBar:self.tabBarController.tabBar];
    } else if (indexPath.section == ProjectsSection && indexPath.row < self.observation.projectObservations.count) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == MoreSection && indexPath.row == 1) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose how your coordinates are displayed on the website."
                                                                 delegate:self 
                                                        cancelButtonTitle:@"Cancel" 
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Open", @"Obscured", @"Private", nil];
        actionSheet.tag = GeoprivacyActionSheetTag;
        self.currentActionSheet = actionSheet;
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    } else if (indexPath.section == MoreSection && indexPath.row > 1) {
        ObservationFieldValue *ofv = [self.observationFieldValues objectAtIndex:indexPath.row - 2];
        NSMutableString *msg = [NSMutableString stringWithString:ofv.observationField.desc];
        NSArray *projects = [self projectsRequireField:ofv.observationField];
        if (projects.count > 0) {
            [msg appendFormat:@"\n\nRequired by %@", [[projects valueForKey:@"title"] componentsJoinedByString:@", "]];
        }
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:ofv.observationField.name
                                                     message:msg
                                                    delegate:nil 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    } else {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ProjectsSection || indexPath.section == MoreSection) {
        return 44;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
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
    [self dismissModalViewControllerAnimated:YES];
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
                msg = @"You've denied iNaturalist access to certain kinds of data, most likely location data, so some of the photo data couldn't be imported.  To change this, open your Settings app, click Location Services, and make sure Location Services are on for iNaturalist.";
            }
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Import Error"
                                                         message:msg
                                                        delegate:nil 
                                               cancelButtonTitle:@"OK" 
                                               otherButtonTitles:nil];
            [av show];
            self.lastImageReferenceURL = nil;
        }];
    } else {
        self.lastImageReferenceURL = nil;
    }
}

#pragma mark - ObservationDetailViewController
- (void)clickedClear {
    [descriptionTextView setText:nil];
}

- (void)keyboardDone {
    [descriptionTextView resignFirstResponder];
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
                    NSString *msg = [NSString stringWithFormat:@"%@ requires that you fill out the %@ field", 
                                     pof.project.title, 
                                     pof.observationField.name];
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Missing Field"
                                                                 message:msg
                                                                delegate:nil 
                                                       cancelButtonTitle:@"OK" 
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
                                                    cancelButtonTitle:@"Cancel" 
                                               destructiveButtonTitle:@"Delete observation" 
                                                    otherButtonTitles:nil];
    actionSheet.tag = DeleteActionSheetTag;
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)clickedView
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil 
                                                             delegate:self 
                                                    cancelButtonTitle:@"Cancel" 
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"View on iNaturalist.org" , nil];
    actionSheet.tag = ViewActionSheetTag;
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)save
{
    [self uiToObservation];
    for (ObservationFieldValue *ofv in self.observation.observationFieldValues) {
        if (ofv.value == nil || ofv.value.length == 0) {
            [ofv deleteEntity]; 
        }
    }
    [self.observation save];
}

- (IBAction)clickedCancel:(id)sender {
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

- (IBAction)clickedAddPhoto:(id)sender {
    UIActionSheet *photoChoice = [[UIActionSheet alloc] init];
    photoChoice.tag = PhotoActionSheetTag;
    [photoChoice setDelegate:self];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [photoChoice addButtonWithTitle:@"Take a photo"];
        [photoChoice addButtonWithTitle:@"Choose from library"];
        [photoChoice addButtonWithTitle:@"Cancel"];
        [photoChoice setCancelButtonIndex:2];
    } else {
        [photoChoice addButtonWithTitle:@"Choose from library"];
        [photoChoice addButtonWithTitle:@"Cancel"];
        [photoChoice setCancelButtonIndex:1];
    }
    [photoChoice showFromTabBar:self.tabBarController.tabBar];
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
    [self reloadObservationFieldValues];
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
    [self.coverflowView setCurrentIndex:self.coverflowView.numberOfCovers-1];
}

- (void)removePhoto:(ObservationPhoto *)op
{
    [self.observationPhotos removeObject:op];
    self.coverflowView.numberOfCovers = self.observationPhotos.count;
    [self resizeHeaderView];
}

- (void)resizeHeaderView
{
    if (!self.coverflowView) return;
    UIView *headerView = self.tableView.tableHeaderView;
    CGRect r = headerView.bounds;
    if (self.observationPhotos.count > 0) {
        [headerView setBounds:
         CGRectMake(0, 0, r.size.width, self.coverflowView.bounds.size.height)];
    } else {
        [headerView setBounds:
         CGRectMake(0, 0, r.size.width, 0)];
    }
    [self.tableView setNeedsLayout];
    [self.tableView setNeedsDisplay];
    [headerView setNeedsLayout];
    [headerView setNeedsDisplay];
    [self.tableView setTableHeaderView:headerView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self stopUpdatingLocation];
    [self uiToObservation];
    if ([segue.identifier isEqualToString:@"EditLocationSegue"]) {
        EditLocationViewController *vc = (EditLocationViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        if (self.observation.latitude) {
            INatLocation *loc = [[INatLocation alloc] initWithLatitude:self.observation.latitude
                                                             longitude:self.observation.longitude
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
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:[self.observation.latitude doubleValue] 
                                                 longitude:[self.observation.longitude doubleValue]];
    if (!self.geocoder) {
        self.geocoder = [[CLGeocoder alloc] init];
    }
    [self.geocoder cancelGeocode];
    [self.geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *pm = [placemarks firstObject]; 
        if (pm) {
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
        }
    }];
}

- (void)dismissActionSheet
{
    if (!self.currentActionSheet) return;
    [self.currentActionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)doneDatePicker
{
    self.observation.localObservedOn = self.datePicker.date;
    [self dismissActionSheet];
    self.observedAtLabel.text = [self.observation observedOnPrettyString];
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

@end
