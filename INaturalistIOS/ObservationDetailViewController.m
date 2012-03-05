//
//  INObservationFormViewController.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationDetailViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import "PhotoViewController.h"
#import "PhotoSource.h"
#import "EditLocationViewController.h"

static int PhotoActionSheetTag = 0;
static int LocationActionSheetTag = 1;
static int ObservedOnActionSheetTag = 2;
static int LocationTableViewSection = 2;
static int ObservedOnTableViewSection = 3;

@implementation ObservationDetailViewController
@synthesize observedAtLabel;
@synthesize latitudeLabel;
@synthesize longitudeLabel;
@synthesize positionalAccuracyLabel;
@synthesize placeGuessField = _placeGuessField;
@synthesize keyboardToolbar = _keyboardToolbar;
@synthesize saveButton = _saveButton;
@synthesize speciesGuessTextField = _speciesGuessTextField;
@synthesize descriptionTextView;
@synthesize delegate = _delegate;
@synthesize observation = _observation;
@synthesize observationPhotos = _observationPhotos;
@synthesize coverflowView = _coverflowView;
@synthesize locationManager = _locationManager;
@synthesize locationTimer = _locationTimer;
@synthesize geocoder = _geocoder;
@synthesize datePicker = _datePicker;
@synthesize currentActionSheet = _currentActionSheet;

- (void)observationToUI
{
    if (self.observation) {
        [self.speciesGuessTextField setText:self.observation.speciesGuess];
        [self.observedAtLabel setText:self.observation.observedOnPrettyString];
        [self.placeGuessField setText:self.observation.placeGuess];
        if (self.observation.latitude) [latitudeLabel setText:self.observation.latitude.description];
        if (self.observation.longitude) [longitudeLabel setText:self.observation.longitude.description];
                                    
        if (self.observation.positionalAccuracy) {
            [positionalAccuracyLabel setText:self.observation.positionalAccuracy.description];
        }
        [descriptionTextView setText:self.observation.inatDescription];
    }
}

- (void)uiToObservation
{
    if (!self.speciesGuessTextField) return;
    [self.observation setSpeciesGuess:[self.speciesGuessTextField text]];
    [self.observation setInatDescription:[descriptionTextView text]];
    [self.observation setPlaceGuess:[self.placeGuessField text]];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    self.observation.latitude = [numberFormatter numberFromString:self.latitudeLabel.text];
    self.observation.longitude = [numberFormatter numberFromString:self.longitudeLabel.text];
    self.observation.positionalAccuracy = [numberFormatter 
                                           numberFromString:self.positionalAccuracyLabel.text];
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
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self setToolbarItems:[NSArray arrayWithObjects:
                           flex, 
                           self.saveButton, 
                           flex, nil]
                 animated:YES];
    
    [self refreshCoverflowView];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    NSLog(@"viewDidLoad");
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self observationToUI];
    if ([self.observation isNew]) {
        [[self navigationItem] setTitle:@"Add observation"];
    } else {
        [[self navigationItem] setTitle:@"Edit observation"];
    }
}

- (void)startUpdatingLocation
{
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
    NSLog(@"stopping location updates");
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
    if (self.locationTimer) {
        [self.locationTimer invalidate];
        self.locationTimer = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"viewWillAppear");
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear, saveButton: %@", self.saveButton);
    [self initUI];
    if (self.observation.isNew && [self.latitudeLabel.text isEqualToString:@"???"]) {
        [self startUpdatingLocation];
    }
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"didReceiveMemoryWarning");
    // Releases the view if it doesn't have a superview.
    self.coverflowView = nil;
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    // ensure UI state gets stored in the observation
    [self uiToObservation];
    
    [self setSpeciesGuessTextField:nil];
    [self setObservedAtLabel:nil];
    [self setLatitudeLabel:nil];
    [self setLongitudeLabel:nil];
    [self setPositionalAccuracyLabel:nil];
    [self setDescriptionTextView:nil];
    [self setDescriptionTextView:nil];
    [self setKeyboardToolbar:nil];
    [self setSaveButton:nil];
    [self stopUpdatingLocation];
    [self setLocationManager:nil];
    [self setPlaceGuessField:nil];
    [self setGeocoder:nil];
    [self setDatePicker:nil];
    [self setCurrentActionSheet:nil];
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
    [op setObservation:self.observation];
    [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
    [ImageStore.sharedImageStore store:[info objectForKey:UIImagePickerControllerOriginalImage] 
                                forKey:op.photoKey];
    [self addPhoto:op];
}


#pragma mark TKCoverflowViewDelegate methods
- (void)initCoverflowView
{
    NSLog(@"initCoverflowView");
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
    [self.tableView.tableHeaderView addSubview:self.coverflowView];
}

- (void)refreshCoverflowView
{
    NSLog(@"refreshCoverflowView");
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
	NSLog(@"Front %d",index);
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
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark UIViewController
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == PhotoActionSheetTag) {
        [self photoActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    } else {
        [self locationActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
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
    
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    [ipc setDelegate:self];
    [ipc setSourceType:sourceType];
    [self presentModalViewController:ipc animated:YES];
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

#pragma mark PhotoViewControllerDelegate
- (void)photoViewControllerDeletePhoto:(id<TTPhoto>)photo
{
    NSLog(@"photoViewControllerDeletePhoto, photo: %@", photo);
    ObservationPhoto *op = (ObservationPhoto *)photo;
    [self.observationPhotos removeObject:op];
    [op deleteEntity];
    [self refreshCoverflowView];
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (newLocation.timestamp.timeIntervalSinceNow < -60) {
        return;
    }
    
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
        self.datePicker.date = self.observation.observedOn;
        [sheet addSubview:self.datePicker];
        
        [sheet showFromTabBar:self.tabBarController.tabBar];
    }
}

# pragma mark - EditLocationViewControllerDelegate
- (void)editLocationViewControllerDidSave:(EditLocationViewController *)controller location:(INatLocation *)location
{
    self.latitudeLabel.text = [NSString stringWithFormat:@"%f", [location.latitude doubleValue]];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%f", [location.longitude doubleValue]];
    self.observation.positioningMethod = location.positioningMethod;
    [self reverseGeocodeCoordinates];
    if (location.accuracy) {
        self.positionalAccuracyLabel.text = [NSString stringWithFormat:@"%d", [location.accuracy intValue]];
    } else {
        self.positionalAccuracyLabel.text = @"???";
    }
}


#pragma mark ObservationDetailViewController
- (void)clickedClear {
    [descriptionTextView setText:nil];
}

- (void)keyboardDone {
    [descriptionTextView resignFirstResponder];
}

- (void)clickedSave {
    [self save];
    [self.delegate observationDetailViewControllerDidSave:self];
}

- (void)save
{
    [self uiToObservation];
    [self.observation save];
}

- (IBAction)clickedCancel:(id)sender {
    if ([self.observation isNew]) {
        NSLog(@"obs was new, destroying");
        [self.observation destroy];
    } else {
        [self.observation.managedObjectContext undo];
    }
    [self.delegate observationDetailViewControllerDidCancel:self];
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
}

- (NSMutableArray *)observationPhotos
{
    if (!_observationPhotos) {
        self.observationPhotos = [[NSMutableArray alloc] init];
    }
    return _observationPhotos;
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
    if ([segue.identifier isEqualToString:@"EditLocationSegue"]) {
        [self stopUpdatingLocation];
        EditLocationViewController *vc = (EditLocationViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        [self uiToObservation];
        if (self.observation.latitude) {
            INatLocation *loc = [[INatLocation alloc] initWithLatitude:self.observation.latitude
                                                             longitude:self.observation.longitude
                                                              accuracy:self.observation.positionalAccuracy];
            loc.positioningMethod = self.observation.positioningMethod;
            [vc setCurrentLocation:loc];
        }
    }
}

- (void)reverseGeocodeCoordinates
{
    [self uiToObservation];
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
    self.observation.observedOn = self.datePicker.date;
    [self dismissActionSheet];
    self.observedAtLabel.text = [self.observation observedOnPrettyString];
}

@end
