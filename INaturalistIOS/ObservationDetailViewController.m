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

@implementation ObservationDetailViewController
@synthesize observedAtLabel;
@synthesize latitudeLabel;
@synthesize longitudeLabel;
@synthesize positionalAccuracyLabel;
@synthesize keyboardToolbar;
@synthesize saveButton;
@synthesize speciesGuessTextField;
@synthesize descriptionTextView;
@synthesize delegate = _delegate;
@synthesize observation = _observation;
@synthesize observationPhotos = _observationPhotos;
@synthesize coverflowView = _coverflowView;

- (void)updateUIWithObservation
{
    if (self.observation) {
        [speciesGuessTextField setText:self.observation.speciesGuess];
        [observedAtLabel setText:self.observation.observedOnString];
        if (self.observation.latitude) [latitudeLabel setText:[self.observation.latitude description]];
        if (self.observation.longitude) [longitudeLabel setText:[NSString stringWithFormat:@"%f", [self.observation.longitude doubleValue]]];
                                    
        if (self.observation.positionalAccuracy) [positionalAccuracyLabel setText:[NSString stringWithFormat:@"%d", self.observation.positionalAccuracy]];
        [descriptionTextView setText:self.observation.inatDescription];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    NSLog(@"viewDidLoad");
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self updateUIWithObservation];
    if ([self.observation isNew]) {
        [[self navigationItem] setTitle:@"New observation"];
    } else {
        [[self navigationItem] setTitle:@"Edit observation"];
    }
    
    [self initCoverflowView];
    [self.navigationController setToolbarHidden:NO animated:YES];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                          target:nil 
                                                                          action:nil];
    [self setToolbarItems:[NSArray arrayWithObjects:
                           flex, 
                           saveButton, 
                           flex, nil]
                 animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"viewWillAppear");
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"didReceiveMemoryWarning");
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    [self.observation save];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    NSLog(@"viewDidUnload");
    [self setSpeciesGuessTextField:nil];
    [self setObservedAtLabel:nil];
    [self setLatitudeLabel:nil];
    [self setLongitudeLabel:nil];
    [self setPositionalAccuracyLabel:nil];
    [self setDescriptionTextView:nil];
    [self setDescriptionTextView:nil];
    [self setKeyboardToolbar:nil];
    [self setSaveButton:nil];
    [self setObservationPhotos:nil];
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
    [textView setInputAccessoryView:keyboardToolbar];
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
    float width = [UIScreen mainScreen].bounds.size.width,
          height = width / 1.342,
          coverDim = height - 10,
          coverWidth = coverDim,
          coverHeight = coverDim;
    CGRect r = CGRectMake(0, 0, width, height);
    self.coverflowView = [[TKCoverflowView alloc] initWithFrame:r];
	self.coverflowView.coverflowDelegate = self;
	self.coverflowView.dataSource = self;
    self.coverflowView.numberOfCovers = [self.observationPhotos count];
    self.coverflowView.coverSize = CGSizeMake(coverWidth, coverHeight);
    [self resizeHeaderView];
    [self.tableView.tableHeaderView addSubview:self.coverflowView];
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
    UIImage *img = [[ImageStore sharedImageStore] find:op.photoKey];
    if (img) {
        cover.image = img;
    }
    return cover;
}

- (void)coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasBroughtToFront:(int)index
{
	NSLog(@"Front %d",index);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



- (IBAction)clickedClear:(id)sender {
    [descriptionTextView setText:nil];
}

- (IBAction)keyboardDone:(id)sender {
    [descriptionTextView resignFirstResponder];
}

- (IBAction)clickedSave:(id)sender {
    [self save];
    [self.delegate observationDetailViewControllerDidSave:self];
}

- (void)save
{
    [self.observation setSpeciesGuess:[speciesGuessTextField text]];
    [self.observation setInatDescription:[descriptionTextView text]];
    [self.observation save];
}

- (IBAction)clickedCancel:(id)sender {
    if ([self.observation isNew]) {
        NSLog(@"obs was new, destroying");
        [self.observation destroy];
    }
    [self.delegate observationDetailViewControllerDidCancel:self];
}

- (IBAction)clickedAddPhoto:(id)sender {
    UIActionSheet *photoChoice = [[UIActionSheet alloc] init];
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
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

- (void)setObservation:(Observation *)observation
{
    _observation = observation;
    
    if (observation && [observation.observationPhotos count] > 0) {
        NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"position" 
                                                                        ascending:YES];
        NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"localCreatedAt" 
                                                                        ascending:YES];
        
        NSArray *sortedObservationPhotos = [observation.observationPhotos 
                                            sortedArrayUsingDescriptors:
                                            [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
        for (ObservationPhoto *op in sortedObservationPhotos) {
            [self addPhoto:op];
        }
    } else {
        [self.observationPhotos removeAllObjects];
    }
}

- (void)addPhoto:(ObservationPhoto *)op
{
    if (!self.observationPhotos) {
        self.observationPhotos = [[NSMutableArray alloc] init];
    }
    [self.observationPhotos addObject:op];
    self.coverflowView.numberOfCovers = [self.observationPhotos count];
    [self.coverflowView setCurrentIndex:self.coverflowView.numberOfCovers-1];
    [self resizeHeaderView];
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
        [self.coverflowView setHidden:NO];
        if (r.size.height < self.coverflowView.bounds.size.height) {
            [headerView setBounds:
             CGRectMake(0, 0, r.size.width, self.coverflowView.bounds.size.height)];
        }
    } else {
        [self.coverflowView setHidden:YES];
        if (r.size.height > self.coverflowView.bounds.size.height) {
            [headerView setBounds:
             CGRectMake(0, 0, r.size.width, 0)];
        }
    }
    [self.tableView setNeedsLayout];
    [self.tableView setNeedsDisplay];
    [headerView setNeedsLayout];
    [headerView setNeedsDisplay];
    [self.tableView setTableHeaderView:headerView];
}

@end
