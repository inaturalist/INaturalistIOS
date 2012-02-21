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
@synthesize tmpImageView;
@synthesize speciesGuessTextField;
@synthesize descriptionTextView;
@synthesize delegate, observation;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)updateUIWithObservation
{
    if (observation) {
        [speciesGuessTextField setText:observation.speciesGuess];
        [observedAtLabel setText:observation.observedOnString];
        if (observation.latitude) [latitudeLabel setText:[observation.latitude description]];
        if (observation.longitude) [longitudeLabel setText:[NSString stringWithFormat:@"%f", [observation.longitude doubleValue]]];
                                    
        if (observation.positionalAccuracy) [positionalAccuracyLabel setText:[NSString stringWithFormat:@"%d", observation.positionalAccuracy]];
        [descriptionTextView setText:observation.inatDescription];
        
        for (ObservationPhoto *op in observation.observationPhotos) {
            [tmpImageView setImage:[ImageStore.sharedImageStore find:op.photoKey]];
            if ([tmpImageView image]) {
                break;
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self updateUIWithObservation];
    if ([observation isNew]) {
        [[self navigationItem] setTitle:@"New observation"];
    } else {
        [[self navigationItem] setTitle:@"Edit observation"];
    }
}

- (void)viewDidUnload
{
    [self setSpeciesGuessTextField:nil];
    [self setObservedAtLabel:nil];
    [self setLatitudeLabel:nil];
    [self setLongitudeLabel:nil];
    [self setPositionalAccuracyLabel:nil];
    [self setObservation:nil];
    [self setDelegate:nil];
    [self setDescriptionTextView:nil];
    [self setDescriptionTextView:nil];
    [self setKeyboardToolbar:nil];
    [self setTmpImageView:nil];
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
    [op setObservation:observation];
    [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
    [ImageStore.sharedImageStore store:[info objectForKey:UIImagePickerControllerOriginalImage] 
                                forKey:op.photoKey];
    [tmpImageView setImage:[ImageStore.sharedImageStore find:op.photoKey]];
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
    [observation setSpeciesGuess:[speciesGuessTextField text]];
    [observation setInatDescription:[descriptionTextView text]];
    [observation save];
}

- (IBAction)clickedCancel:(id)sender {
    if ([observation isNew]) {
        NSLog(@"obs was new, destroying");
        [observation destroy];
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

@end
