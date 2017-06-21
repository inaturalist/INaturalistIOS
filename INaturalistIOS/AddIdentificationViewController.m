//
//  AddIdentificationViewController.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <UIImageView+WebCache.h>
#import <UIView+WebCache.h>

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"IdentificationTaxaSearchSegue"]) {
        TaxaSearchViewController *vc = (TaxaSearchViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        vc.observationToClassify = self.observation;
    }
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

- (IBAction)cancelAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveAction:(id)sender {
    
    BOOL inputValidated = YES;
    NSString *alertMsg;
    
    if (!self.observation || ![self.observation inatRecordId]) {
        inputValidated = NO;
        alertMsg = NSLocalizedString(@"Unable to add an identification to this observation. Please try again later.",
                                     @"Failure message when making an identification");
    } else if (!self.taxon) {
        inputValidated = NO;
        alertMsg = NSLocalizedString(@"Unable to identify this observation to that species. Please try again later.",
                                     @"Failure message when making an identification");
    }
    
    if (!inputValidated) {
        NSString *alertTitle = NSLocalizedString(@"Identification Failed", @"Title of identification failure alert");
        if (!alertMsg) {
            alertMsg = NSLocalizedString(@"Unknown error while making an identification.", @"Unknown error");
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    NSDictionary *params = @{
                             @"identification[body]": self.descriptionTextView.text,
                             @"identification[observation_id]": @([self.observation inatRecordId]),
                             @"identification[taxon_id]": @([self.taxon taxonId])
                             };
    [[Analytics sharedClient] debugLog:@"Network - Add Identification"];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Saving...",nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
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
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    if (response.statusCode == 200) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                                                       message:NSLocalizedString(@"An unknown error occured. Please try again.", @"unknown error adding ID")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TaxaSearchViewControllerDelegate
- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxon
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.taxon = taxon;
    [self taxonToUI];
}

- (void)taxaSearchViewControllerCancelled {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)taxonToUI
{
    [self.speciesGuessTextField setText:self.taxon.commonName ?: self.taxon.scientificName];
    
    UITableViewCell *speciesCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIImageView *img = (UIImageView *)[speciesCell viewWithTag:1];
    UIButton *rightButton = (UIButton *)[speciesCell viewWithTag:3];
    img.layer.cornerRadius = 5.0f;
    img.clipsToBounds = YES;
    [img sd_cancelCurrentImageLoad];
    
    if (self.taxon) {
        img.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName];
        if ([self.taxon photoUrl]) {
            [img sd_setImageWithURL:[self.taxon photoUrl]
                   placeholderImage:[[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName]];
        }
        self.speciesGuessTextField.enabled = NO;
        rightButton.imageView.image = [UIImage imageNamed:@"298-circlex"];
    } else {
        rightButton.imageView.image = [UIImage imageNamed:@"06-magnify"];
        self.speciesGuessTextField.enabled = YES;
        self.speciesGuessTextField.textColor = [UIColor blackColor];
    }
}

@end
