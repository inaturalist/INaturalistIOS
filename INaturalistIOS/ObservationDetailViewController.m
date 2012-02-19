//
//  INObservationFormViewController.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationDetailViewController.h"
#import "Observation.h"

@implementation ObservationDetailViewController
@synthesize observedAtLabel;
@synthesize latitudeLabel;
@synthesize longitudeLabel;
@synthesize positionalAccuracyLabel;
@synthesize keyboardToolbar;
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
        [speciesGuessTextField setText:observation.species_guess];
        [observedAtLabel setText:observation.observed_on_string];
        if (observation.latitude) [latitudeLabel setText:[observation.latitude description]];
        if (observation.longitude) [longitudeLabel setText:[NSString stringWithFormat:@"%f", [observation.longitude doubleValue]]];
                                    
        if (observation.positional_accuracy) [positionalAccuracyLabel setText:[NSString stringWithFormat:@"%d", observation.positional_accuracy]];
        [descriptionTextView setText:observation.inat_description];
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
    [observation setSpecies_guess:[speciesGuessTextField text]];
    [observation setInat_description:[descriptionTextView text]];
    [observation save];
}

- (IBAction)clickedCancel:(id)sender {
    if ([observation isNew]) {
        NSLog(@"obs was new, destroying");
        [observation destroy];
    }
    [self.delegate observationDetailViewControllerDidCancel:self];
}

@end
