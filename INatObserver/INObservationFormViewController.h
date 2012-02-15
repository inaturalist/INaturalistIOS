//
//  INObservationFormViewController.h
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Observation;
@class INObservationFormViewController;

@protocol INObservationFormViewControllerDelegate <NSObject>
- (void)observationFormViewControllerDidSave:(INObservationFormViewController *)controller;
- (void)observationFormViewControllerDidCancel:(INObservationFormViewController *)controller;
@end

//@interface INObservationFormViewController : UIViewController
@interface INObservationFormViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, weak) id <INObservationFormViewControllerDelegate> delegate;
@property (nonatomic, strong) Observation *observation;
@property (weak, nonatomic) IBOutlet UITextField *speciesGuessTextField;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

@property (weak, nonatomic) IBOutlet UILabel *observedAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionalAccuracyLabel;
@property (strong, nonatomic) IBOutlet UIToolbar *keyboardToolbar;

- (IBAction)clickedClear:(id)sender;
- (IBAction)keyboardDone:(id)sender;
- (IBAction)clickedSave:(id)sender;
- (IBAction)clickedCancel:(id)sender;
- (void)save;
- (void)updateUIWithObservation;

@end
