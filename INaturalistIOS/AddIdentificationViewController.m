//
//  AddIdentificationViewController.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "DejalActivityView.h"
#import "AddIdentificationViewController.h"
#import "Observation.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"

@interface AddIdentificationViewController () <RKRequestDelegate>

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
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
	if (!self.taxon) {
		[self performSegueWithIdentifier:@"IdentificationTaxaSearchSegue" sender:nil];
	}
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
	[DejalBezelActivityView activityViewForView:self.view withLabel:NSLocalizedString(@"Saving...",nil)];
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

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
	[DejalBezelActivityView removeView];
	NSLog(@"Response: %@", response);
	if (response.statusCode == 200) {
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		[self showError:@"An unknown error occurred. Please try again."];
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
	[DejalBezelActivityView removeView];
	NSLog(@"Request Error: %@", error.localizedDescription);
	[self showError:error.localizedDescription];
}

- (void)showError:(NSString *)errorMessage{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
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
	TTImageView *img = (TTImageView *)[speciesCell viewWithTag:1];
	UIButton *rightButton = (UIButton *)[speciesCell viewWithTag:3];
	img.style = [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithTopLeft:5
                                                                              topRight:5
                                                                           bottomRight:5
                                                                            bottomLeft:5]
                                        next:[TTContentStyle styleWithNext:nil]];
    [img unsetImage];
    img.defaultImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName];
    if (self.taxon) {
        if (self.taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = (TaxonPhoto *)self.taxon.taxonPhotos.firstObject;
            img.urlPath = tp.squareURL;
        }
        self.speciesGuessTextField.enabled = NO;
        rightButton.imageView.image = [UIImage imageNamed:@"298-circlex.png"];
        self.speciesGuessTextField.textColor = [Taxon iconicTaxonColor:self.taxon.iconicTaxonName];
    } else {
        rightButton.imageView.image = [UIImage imageNamed:@"06-magnify.png"];
        self.speciesGuessTextField.enabled = YES;
        self.speciesGuessTextField.textColor = [UIColor blackColor];
    }
}

@end
