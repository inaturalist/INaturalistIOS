//
//  AddIdentificationViewController.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <UIImageView+WebCache.h>

#import "AddIdentificationViewController.h"
#import "Observation.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "Analytics.h"

@interface AddIdentificationViewController () <RKRequestDelegate> {
    BOOL viewHasPresented;
}
@property (weak, nonatomic) IBOutlet UITextField *speciesGuessTextField;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

- (IBAction)cancelAction:(id)sender;
- (IBAction)saveAction:(id)sender;
- (IBAction)clickedSpeciesButton:(id)sender;

@end

@implementation AddIdentificationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	if (!self.taxon) {
        if (viewHasPresented) {
            // user is trying to cancel adding an ID
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self performSegueWithIdentifier:@"IdentificationTaxaSearchSegue" sender:nil];
        }
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    viewHasPresented = YES;
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateAddIdentification];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateAddIdentification];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"IdentificationTaxaSearchSegue"]) {
        TaxaSearchViewController *vc = (TaxaSearchViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        //vc.query = self.observation.speciesGuess;
    }
}

- (IBAction)cancelAction:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveAction:(id)sender {
    
    BOOL inputValidated = YES;
    NSString *alertMsg;
    
    if (!self.observation || !self.observation.recordID) {
        inputValidated = NO;
        alertMsg = NSLocalizedString(@"Unable to add an identification to this observation. Please try again later.",
                                     @"Failure message when making an identification");
    } else if (!self.taxon || !self.taxon.recordID) {
        inputValidated = NO;
        alertMsg = NSLocalizedString(@"Unable to identify this observation to that species. Please try again later.",
                                     @"Failure message when making an identification");
    }
    
    if (!inputValidated) {
        NSString *alertTitle = NSLocalizedString(@"Identification Failed", @"Title of identification failure alert");
        if (!alertMsg) {
            alertMsg = NSLocalizedString(@"Unknown error while making an identification.", @"Unknown error");
        }
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMsg
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving...",nil)];
	NSDictionary *params = @{
							 @"identification[body]": self.descriptionTextView.text,
							 @"identification[observation_id]": self.observation.recordID,
							 @"identification[taxon_id]": self.taxon.recordID
							 };
	[[RKClient sharedClient] post:@"/identifications" params:params delegate:self];
}

- (IBAction)clickedSpeciesButton:(id)sender {
    if (self.taxon) {
		self.taxon = nil;
		[self taxonToUI];
    } else {
        [self performSegueWithIdentifier:@"IdentificationTaxaSearchSegue" sender:nil];
    }
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
	if (response.statusCode == 200) {
        [SVProgressHUD showSuccessWithStatus:nil];
		[self.navigationController popViewControllerAnimated:YES];
	} else {
        [SVProgressHUD showErrorWithStatus:@"An unknown error occured. Please try again."];
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:error.localizedDescription];
}

#pragma mark - TaxaSearchViewControllerDelegate
- (void)taxaSearchViewControllerChoseTaxon:(Taxon *)taxon
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.taxon = taxon;
	[self taxonToUI];
	
	NSLog(@"chose taxon: %@", taxon.defaultName);
}

- (void)taxonToUI
{
	[self.speciesGuessTextField setText:self.taxon.defaultName];
    
	UITableViewCell *speciesCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	UIImageView *img = (UIImageView *)[speciesCell viewWithTag:1];
	UIButton *rightButton = (UIButton *)[speciesCell viewWithTag:3];
    img.layer.cornerRadius = 5.0f;
    img.clipsToBounds = YES;
    [img sd_cancelCurrentImageLoad];
    
    img.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName];
    if (self.taxon) {
        if (self.taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = (TaxonPhoto *)self.taxon.taxonPhotos.firstObject;
            [img sd_setImageWithURL:[NSURL URLWithString:tp.squareURL]
                   placeholderImage:[[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName]];
        }
        self.speciesGuessTextField.enabled = NO;
        rightButton.imageView.image = [UIImage imageNamed:@"298-circlex"];
        self.speciesGuessTextField.textColor = [Taxon iconicTaxonColor:self.taxon.iconicTaxonName];
    } else {
        rightButton.imageView.image = [UIImage imageNamed:@"06-magnify"];
        self.speciesGuessTextField.enabled = YES;
        self.speciesGuessTextField.textColor = [UIColor blackColor];
    }
}

@end
