//
//  INObservationFormViewController.h
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Observation;
@class ObservationDetailViewController;

@protocol ObservationDetailViewControllerDelegate <NSObject>
- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller;
- (void)observationDetailViewControllerDidCancel:(ObservationDetailViewController *)controller;
@end

@interface ObservationDetailViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, weak) id <ObservationDetailViewControllerDelegate> delegate;
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
